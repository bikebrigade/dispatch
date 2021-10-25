defmodule BikeBrigade.Messaging do
  @moduledoc """
  The Messaging context.
  """
  import BikeBrigade.Utils
  import Ecto.Query, warn: false
  alias BikeBrigade.Repo

  alias BikeBrigade.Messaging.{SmsMessage, ScheduledMessage}
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

  @doc """
  Returns pairs of riders and the last message, sorted by last message sent
  """
  def list_sms_conversations(opts \\ []) do
    query =
      from r in Rider,
        as: :rider,
        inner_lateral_join:
          latest_message in subquery(
            from m in SmsMessage,
              where: m.rider_id == parent_as(:rider).id,
              order_by: [desc: m.sent_at],
              limit: 1
          ),
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

  @doc "Creates a struct for a new outgoing message"
  def new_sms_message() do
    from = outbound_number()
    %SmsMessage{from: from}
  end

  def new_sms_message(%Rider{} = rider, sent_by_user \\ nil) do
    from =
      if rider.flags.opt_in_to_new_number do
        new_outbound_number()
      else
        outbound_number()
      end

    sent_by_user_id = if sent_by_user, do: sent_by_user.id

    %SmsMessage{
      from: from,
      to: rider.phone,
      rider_id: rider.id,
      sent_by_user_id: sent_by_user_id,
      incoming: false
    }
  end

  @doc "Send a message and save it in the database"
  def send_sms_message(%SmsMessage{} = sms_message, attrs \\ %{}) do
    sms_message_changeset = send_sms_message_changeset(sms_message, attrs)

    with {:ok, sms_msg} <-
           Ecto.Changeset.apply_action(sms_message_changeset, :insert),
         {:ok, _} <- maybe_send_initial_message(sms_msg),
         # apply action instead of repo.insert since we only want to insert on successful sends
         {:ok, twilio_msg} <- SmsService.send_sms(sms_msg, send_callback: true) do
      create_sms_message(sms_msg, %{
        sent_at: DateTime.utc_now(),
        twilio_status: twilio_msg.status,
        twilio_sid: twilio_msg.sid
      })
    else
      {:error, %Ecto.Changeset{} = changeset} ->
        {:error, changeset}

      {:error, reason} ->
        {:error,
         sms_message_changeset
         |> Ecto.Changeset.add_error(:body, reason)
         |> Map.put(:action, :validate)}
    end
  end

  defp maybe_send_initial_message(%SmsMessage{rider_id: rider_id}) when not is_nil(rider_id) do
    with rider when not is_nil(rider) <- BikeBrigade.Riders.get_rider(rider_id),
         %Rider.Flags{opt_in_to_new_number: true, initial_message_sent: false} <- rider.flags do
      # TODO: is this a race condition / what happens if this fails?
      Riders.update_rider(rider, %{flags: %{initial_message_sent: true}})

      new_sms_message(rider)
      |> send_sms_message(%{body: @initial_message})
    else
      %Rider.Flags{} -> {:ok, nil}
      {:error, err} -> {:error, err}
    end
  end

  def list_unsent_scheduled_messages do
    q =
      from s in ScheduledMessage,
        where: s.send_at <= ^DateTime.utc_now()

    Repo.all(q)
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
    message = message
    |> Repo.preload(campaign: [:program])

    message.campaign.program.name
  end

  def sent_by_user_name(message) do
    message = message
    |> Repo.preload(:sent_by_user)

    message.sent_by_user.name
  end
end
