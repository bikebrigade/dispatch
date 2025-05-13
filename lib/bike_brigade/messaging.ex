defmodule BikeBrigade.Messaging do
  @moduledoc """
  The Messaging context.
  """
  import BikeBrigade.Utils
  import Ecto.Query, warn: false
  alias BikeBrigade.Repo

  alias BikeBrigade.Messaging.{SmsMessage, ScheduledMessage, Banner}
  alias BikeBrigade.Riders
  alias BikeBrigade.Riders.Rider
  alias BikeBrigade.SmsService

  @initial_message "Hello! This is the Bike Brigade number. The team uses this number to send you information about deliveries you sign up for, and you can text us here if you have any questions. This number is monitored by the Bike Brigade team -- we'll often sign messages with the person sending them.\n\nWe recommend you add this number to your contacts as Bike Brigade (or update your contacts if you've added our old number).\n\nYou can text STOP to this number to opt-out of receiving text messages from us."

  @doc """
  Returns the list of sms_messages.

  ## Examples

      iex> list_sms_messages()
      [%SmsMessage{}, ...]

  """
  def list_sms_messages do
    Repo.all(SmsMessage)
  end

  # Private function to get the latest message subquery
  defp get_latest_message_subquery() do
    subquery(
      from m in SmsMessage,
        where: m.rider_id == parent_as(:rider).id,
        order_by: [desc: m.sent_at],
        limit: 1
    )
  end

  @doc """
  Returns pairs of riders and the last message, sorted by last message sent
  """
  def list_sms_conversations(opts \\ []) do
    query =
      from r in Rider,
        as: :rider,
        inner_lateral_join: latest_message in ^get_latest_message_subquery(),
        on: true,
        order_by: [desc: latest_message.sent_at],
        select: {r, latest_message}

    query =
      if limit = opts[:limit] do
        query |> limit(^limit)
      else
        query
      end

    Repo.all(query)
  end

  @doc """
  Used to fetch sms conversations from riders who are riding for a specific
  campaign. It uses a left_lateral_join (as opposed to the inner_lateral_join in
  `list_sms_conversastions`) because we need to return all riders from the
  passed in list, even if they have no sms history (albeit unlikely)).
  """
  def list_sms_conversations_for_riders(rider_ids) do
    query =
      from r in Rider,
        as: :rider,
        left_lateral_join: latest_message in ^get_latest_message_subquery(),
        on: true,
        order_by: [desc: latest_message.sent_at],
        select: {r, latest_message},
        where: r.id in ^rider_ids

    Repo.all(query)
  end

  @doc """
  Returns latest messages for a rider, with limit and offset
  """
  def latest_messages(%Rider{} = rider, before \\ nil, limit \\ 10) do
    query =
      from m in SmsMessage,
        where: m.rider_id == ^rider.id,
        limit: ^limit,
        order_by: [desc: m.sent_at]

    query =
      if before do
        query
        |> where([m], m.sent_at < ^before)
      else
        query
      end

    Repo.all(query)
    |> Repo.preload(:sent_by_user)
    |> Enum.reverse()
  end

  @doc """
  Gets a single sms_message.

  Raises `Ecto.NoResultsError` if the Sms message does not exist.

  ## Examples

      iex> get_sms_message!(123)
      %SmsMessage{}

      iex> get_sms_message!(456)
      ** (Ecto.NoResultsError)

  """
  def get_sms_message!(id), do: Repo.get!(SmsMessage, id)

  def get_sms_message_by_twilio_sid(sid), do: Repo.get_by(SmsMessage, twilio_sid: sid)

  @doc """
  Creates a sms_message.

  ## Examples

      iex> create_sms_message(%{field: value})
      {:ok, %SmsMessage{}}

      iex> create_sms_message(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_sms_message(sms_message \\ %SmsMessage{}, attrs) do
    sms_message
    |> SmsMessage.changeset(attrs)
    |> Repo.insert()
    |> broadcast(:message_created)
  end

  @doc """
  Updates a sms_message.

  ## Examples

      iex> update_sms_message(sms_message, %{field: new_value})
      {:ok, %SmsMessage{}}

      iex> update_sms_message(sms_message, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_sms_message(%SmsMessage{} = sms_message, attrs) do
    sms_message
    |> SmsMessage.changeset(attrs)
    |> Repo.update()
    |> broadcast(:message_updated)
  end

  @doc """
  Deletes a sms_message.

  ## Examples

      iex> delete_sms_message(sms_message)
      {:ok, %SmsMessage{}}

      iex> delete_sms_message(sms_message)
      {:error, %Ecto.Changeset{}}

  """
  def delete_sms_message(%SmsMessage{} = sms_message) do
    Repo.delete(sms_message)
  end

  @doc """
  Creates a struct for a new outgoing message
  """
  def new_sms_message() do
    from = outbound_number()
    %SmsMessage{from: from}
  end

  @doc """
  Creates a struct for a new outgoing message for a given a `%Rider{}`

  Optional arguments
    - `sent_by:` - `%Accounts.User{}` that's sending the message
    - `body:` - string containing the body of the message
  """
  def new_sms_message(%Rider{} = rider, options \\ []) do
    from =
      if rider.flags.opt_in_to_new_number do
        new_outbound_number()
      else
        outbound_number()
      end

    sent_by_user_id =
      if user = Keyword.get(options, :sent_by) do
        user.id
      end

    body = Keyword.get(options, :body)

    %SmsMessage{
      from: from,
      to: rider.phone,
      rider_id: rider.id,
      body: body,
      sent_by_user_id: sent_by_user_id,
      incoming: false
    }
  end

  @doc "Send a message and save it in the database"
  def send_sms_message(%SmsMessage{} = sms_message, attrs \\ %{}) do
    # TODO this preload is because we update rider later, would be nice to just have a special changeset for this bit so we dont need to preload
    sms_message = sms_message |> Repo.preload(rider: [:location])

    Ecto.Multi.new()
    |> maybe_send_initial_message(sms_message.rider)
    |> Ecto.Multi.run(:create_message, fn _repo, _changes ->
      send_sms_message_changeset(sms_message, attrs)
      |> Ecto.Changeset.apply_action(:insert)
    end)
    |> Ecto.Multi.run(:send_message, fn _repo, %{create_message: sms_message} ->
      SmsService.send_sms(sms_message, send_callback: true)
    end)
    |> Ecto.Multi.run(
      :save_message,
      fn _repo, %{create_message: sms_message, send_message: twilio_msg} ->
        create_sms_message(sms_message, %{
          sent_at: DateTime.utc_now(),
          twilio_status: twilio_msg.status,
          twilio_sid: twilio_msg.sid
        })
      end
    )
    |> Repo.transaction()
    |> case do
      {:ok, %{save_message: sms_message}} ->
        {:ok, sms_message}

      {:error, :create_message, changeset, _changes} ->
        {:error, changeset}

      {:error, :save_message, changeset, _changes} ->
        {:error, changeset}

      {:error, :send_message, reason, %{create_message: sms_message}} ->
        message_error(sms_message, "Failed to send message: #{reason}")

      {:error, name, reason, %{create_message: sms_message}} ->
        message_error(sms_message, "Failed in step #{name} for #{inspect(reason)}")
    end
  end

  def send_message_in_chunks(campaign, body, rider) do
    # TODO, split SMS semantically somehow

    if String.length(body) > 1500 do
      parts =
        body
        |> String.codepoints()
        |> Enum.chunk_every(1000)
        |> Enum.map(&Enum.join/1)

      [first | rest] = parts
      msg = new_sms_message(rider)

      send_sms_message(msg, %{campaign_id: campaign.id, body: first <> "..."})

      for part <- rest do
        msg = new_sms_message(rider)
        send_sms_message(msg, %{campaign_id: campaign.id, body: "..." <> part})
      end
    else
      msg = new_sms_message(rider)
      send_sms_message(msg, %{campaign_id: campaign.id, body: body})
    end
  end

  defp maybe_send_initial_message(%Ecto.Multi{} = multi, nil), do: multi

  defp maybe_send_initial_message(%Ecto.Multi{} = multi, %Rider{} = rider) do
    case rider.flags do
      %Rider.Flags{opt_in_to_new_number: true, initial_message_sent: false} ->
        initial_message = new_sms_message(rider, body: @initial_message)

        multi
        |> Ecto.Multi.update(
          :update_rider_flags,
          Riders.change_rider(rider, %{flags: %{initial_message_sent: true}})
        )
        |> Ecto.Multi.run(:send_initial_message, fn _repo, _changes ->
          SmsService.send_sms(initial_message, send_callback: true)
        end)
        |> Ecto.Multi.run(
          :save_initial_message,
          fn _repo, %{send_initial_message: twilio_msg} ->
            create_sms_message(initial_message, %{
              sent_at: DateTime.utc_now(),
              twilio_status: twilio_msg.status,
              twilio_sid: twilio_msg.sid
            })
          end
        )

      _ ->
        multi
    end
  end

  defp message_error(%SmsMessage{} = sms_message, error) do
    sms_message
    |> Ecto.Changeset.change()
    |> Ecto.Changeset.add_error(:other_error, error)
    |> Ecto.Changeset.apply_action(:save)
  end

  def list_unsent_scheduled_messages(opts \\ []) do
    {lock, opts} = Keyword.pop(opts, :lock, false)

    q =
      if lock do
        from s in ScheduledMessage,
          where: s.send_at <= ^DateTime.utc_now(),
          lock: "FOR UPDATE SKIP LOCKED"
      else
        from s in ScheduledMessage,
          where: s.send_at <= ^DateTime.utc_now()
      end

    Repo.all(q, opts)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking sms_message changes for a message to be sent.

  """
  def send_sms_message_changeset(%SmsMessage{} = sms_message, attrs \\ %{}) do
    SmsMessage.send_changeset(sms_message, attrs)
  end

  def subscribe do
    Phoenix.PubSub.subscribe(BikeBrigade.PubSub, "messaging")
  end

  defp broadcast({:error, _reason} = error, _event), do: error

  defp broadcast({:ok, struct}, event) do
    Phoenix.PubSub.broadcast(BikeBrigade.PubSub, "messaging", {event, struct})
    {:ok, struct}
  end

  def outbound_number do
    get_config(:outbound_number)
  end

  def new_outbound_number do
    get_config(:new_outbound_number)
  end

  def inbound_number do
    hd(all_inbound_numbers())
  end

  def inbound_number(rider) do
    if rider.flags.opt_in_to_new_number do
      new_outbound_number()
    else
      outbound_number()
    end
  end

  def all_inbound_numbers do
    if inbound_numbers = get_config(:inbound_numbers) do
      String.split(inbound_numbers, " ")
    else
      [get_config(:outbound_number)]
    end
  end

  def brigade_number?(phone) do
    phone in all_inbound_numbers()
  end

  # TODO move this?
  def campaign_name(message) do
    message =
      message
      |> Repo.preload(campaign: [:program])

    message.campaign.program.name
  end

  def sent_by_user_name(message) do
    message =
      message
      |> Repo.preload(:sent_by_user)

    message.sent_by_user.name
  end


  def update_banner(%Banner{} = banner, attrs) do

    IO.inspect(banner, label: ">>>>>>>>>>>>>>>")

    banner
    |> Banner.changeset(attrs)
    |> Repo.update()
    |> broadcast(:banner_updated)
  end


  def create_banner(banner \\ %Banner{}, attrs) do
    banner
    |> Banner.changeset(attrs)
    |> Repo.insert()
    |> broadcast(:banner_created)
  end

  def list_banners() do
    Repo.all(Banner)
  end

  def new_banner() do
    %Banner{}
  end

  def banner_changeset(banner \\ %Banner{}, attrs) do
    banner
    |> Banner.changeset(attrs)
  end

  def get_banner!(id), do: Repo.get!(Banner, id)

end
