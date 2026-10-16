defmodule BikeBrigade.Messaging.Inbox do
  @moduledoc "Campaign and saved-recipient organization of individual SMS conversations."
  import Ecto.Query
  alias BikeBrigade.{Repo, Messaging, Riders}
  alias BikeBrigade.Messaging.BulkMessageGroup

  def enabled?(user), do: get_in(user.flags || %{}, ["unified_messaging"]) == true

  def groups do
    Repo.all(
      from g in BulkMessageGroup,
        order_by: [desc: g.inserted_at, desc: g.id],
        preload: [:creator, :riders]
    )
  end

  def campaigns(user, mine) do
    first = Date.beginning_of_week(BikeBrigade.LocalizedDateTime.today())
    # Query Toronto-local boundaries, including campaigns crossing the week boundary.
    start_at =
      first |> NaiveDateTime.new!(~T[00:00:00]) |> BikeBrigade.LocalizedDateTime.localize()

    end_at =
      Date.add(first, 7)
      |> NaiveDateTime.new!(~T[00:00:00])
      |> BikeBrigade.LocalizedDateTime.localize()

    Repo.all(
      from c in BikeBrigade.Delivery.Campaign,
        join: p in assoc(c, :program),
        where: c.delivery_start < ^end_at and c.delivery_end > ^start_at,
        where: ^(!mine) or p.lead_id == ^user.id,
        order_by: [asc: c.delivery_start, asc: c.id],
        preload: [:program, :riders]
    )
  end

  def validate(ids, body, opts \\ []) do
    body = String.trim(body || "")
    name = String.trim(Keyword.get(opts, :name, ""))

    cond do
      ids == [] ->
        {:error, "Select at least one rider."}

      (body == "" and Keyword.get(opts, :media, []) == []) or String.length(body) > 1600 ->
        {:error, "Enter a message of up to 1600 characters."}

      Keyword.get(opts, :save, false) and (name == "" or String.length(name) > 100) ->
        {:error, "Enter a group name of up to 100 characters."}

      true ->
        :ok
    end
  end

  def send(user, ids, body, opts \\ []) do
    body = String.trim(body || "")
    riders = Riders.get_riders(Enum.uniq(ids))
    name = String.trim(Keyword.get(opts, :name, ""))
    save = Keyword.get(opts, :save, false)

    cond do
      riders == [] ->
        {:error, "Select at least one rider."}

      (body == "" and Keyword.get(opts, :media, []) == []) or String.length(body) > 1600 ->
        {:error, "Enter a message of up to 1600 characters."}

      save and (name == "" or String.length(name) > 100) ->
        {:error, "Enter a group name of up to 100 characters."}

      true ->
        group_result =
          if save do
            %BulkMessageGroup{creator_id: user.id}
            |> BulkMessageGroup.changeset(%{
              name: name,
              body: if(body == "", do: "Attachment", else: body)
            })
            |> Ecto.Changeset.put_assoc(:riders, riders)
            |> Repo.insert()
          else
            {:ok, nil}
          end

        with {:ok, group} <- group_result do
          results =
            Enum.map(riders, fn rider ->
              message = Messaging.new_sms_message(rider, sent_by: user)

              attrs = %{
                body: body,
                campaign_id: Keyword.get(opts, :campaign_id),
                media: Keyword.get(opts, :media, [])
              }

              {rider, Messaging.send_sms_message(message, attrs)}
            end)

          {sent, failed} =
            Enum.split_with(results, fn {_, result} -> match?({:ok, _}, result) end)

          {:ok,
           %{
             group: group,
             sent: length(sent),
             failed: Enum.map(failed, fn {rider, _} -> rider end)
           }}
        end
    end
  end
end
