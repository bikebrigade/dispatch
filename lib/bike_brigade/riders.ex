defmodule BikeBrigade.Riders do
  @moduledoc """
  The Riders context.
  """

  import Ecto.Query, warn: false
  alias BikeBrigade.Repo
  alias BikeBrigade.LocalizedDateTime

  alias BikeBrigade.Riders.{Rider, Tag}
  alias BikeBrigade.Delivery.Campaign

  alias BikeBrigade.EctoPhoneNumber

  @doc """
  Returns the list of riders.

  ## Examples

      iex> list_riders()
      [%Rider{}, ...]

  """
  def list_riders(opts \\ []) do
    Repo.all(Rider)
    |> do_preload(opts)
  end

  # todo add opts
  def list_riders_with_tag(tag) do
    tag =
      Repo.get_by(Tag, name: tag)
      |> Repo.preload(:riders)

    if tag, do: tag.riders, else: []
  end

  # TODO cache this
  def list_tags() do
    Tag
    |> Repo.all()
  end

  # TODO we can do this in memory
  def search_tags(search \\ "", limit \\ 10) do
    Tag
    |> where([u], ilike(u.name, ^"%#{search}%"))
    |> limit(^limit)
    |> Repo.all()
  end

  @doc """
  Gets a single rider.

  Raises `Ecto.NoResultsError` if the Rider does not exist.

  ## Examples

      iex> get_rider!(123)
      %Rider{}

      iex> get_rider!(456)
      ** (Ecto.NoResultsError)

  """
  def get_rider(id, opts \\ []) do
    Repo.get(Rider, id)
    |> do_preload(opts)
  end

  def get_rider!(id, opts \\ []) do
    Repo.get!(Rider, id)
    |> do_preload(opts)
  end

  def get_riders(ids, opts \\ []) do
    from(r in Rider, where: r.id in ^ids)
    |> Repo.all()
    |> do_preload(opts)
  end

  def get_rider_by_email!(email, opts \\ []) do
    email = String.downcase(email)

    Repo.get_by!(Rider, email: email)
    |> do_preload(opts)
  end

  def get_rider_by_email(email, opts \\ []) do
    email = String.downcase(email)

    Repo.get_by(Rider, email: email)
    |> do_preload(opts)
  end

  def get_rider_by_phone!(phone, opts \\ []) do
    case EctoPhoneNumber.Canadian.cast(phone) do
      {:ok, phone} ->
        Repo.get_by!(Rider, phone: phone)
        |> do_preload(opts)

      {:error, err} ->
        raise EctoPhoneNumber.InvalidNumber, message: err
    end
  end

  def get_rider_by_phone(phone, opts \\ []) do
    case BikeBrigade.EctoPhoneNumber.Canadian.cast(phone) do
      {:ok, phone} ->
        Repo.get_by(Rider, phone: phone)
        |> do_preload(opts)

      {:error, _err} ->
        nil
    end
  end

  def list_campaigns_with_task_counts(rider, date \\ nil) do
    where =
      if date do
        start_of_day = LocalizedDateTime.new!(date, ~T[00:00:00])
        end_of_day = LocalizedDateTime.new!(date, ~T[23:59:59])

        dynamic(
          as(:campaign).delivery_start >= ^start_of_day and
            as(:campaign).delivery_start <= ^end_of_day
        )
      else
        true
      end

    query =
      from c in Campaign,
        as: :campaign,
        join: r in assoc(c, :riders),
        where: r.id == ^rider.id,
        left_join: t in assoc(c, :tasks),
        on: t.assigned_rider_id == ^rider.id,
        group_by: c.id,
        order_by: [asc: c.delivery_start],
        where: ^where,
        preload: [:program],
        select: {c, count(t)}

    Repo.all(query)
  end

  @doc """
  Creates a rider.

  ## Examples

      iex> create_rider(%{field: value})
      {:ok, %Rider{}}

      iex> create_rider(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_rider(attrs \\ %{}, opts \\ []) do
    %Rider{}
    |> Rider.changeset(attrs)
    |> Repo.insert(opts)
    |> broadcast(:rider_created)
  end

  # TODO: make it pretty

  def create_rider_with_tags(attrs \\ %{}, tags \\ [], opts \\ []) do
    %Rider{}
    |> Rider.changeset(attrs)
    |> Rider.tags_changeset(tags)
    |> Repo.insert(opts)
    |> broadcast(:rider_created)
  end

  @doc """
  Updates a rider.

  ## Examples

      iex> update_rider(rider, %{field: new_value})
      {:ok, %Rider{}}

      iex> update_rider(rider, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_rider(%Rider{} = rider, attrs) do
    rider
    |> Rider.changeset(attrs)
    |> Repo.update()
    |> broadcast(:rider_updated)
  end

  # TODO: make it pretty
  def update_rider_with_tags(%Rider{} = rider, attrs, tags \\ []) do
    rider
    |> Rider.changeset(attrs)
    |> Rider.tags_changeset(tags)
    |> Repo.update()
    |> broadcast(:rider_updated)
  end

  @doc """
  Removes a rider.

  Rider rows aren't deleted so we maintain records of campaigns
  Instead when a rider is removed we soft delete it:
  - Mark the Rider as removed
  - Delete all PII
  - Delete our SMS correspondence with them
  """
  def remove_rider(%Rider{} = rider) do
    rider
    |> Repo.preload([:location, :messages, :tags, :user])
    |> Rider.soft_delete_changeset()
    |> Repo.update()
    |> broadcast(:rider_updated)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking rider changes.

  ## Examples

      iex> change_rider(rider)
      %Ecto.Changeset{data: %Rider{}}

  """
  def change_rider(%Rider{} = rider, attrs \\ %{}) do
    Rider.changeset(rider, attrs)
  end

  def count_riders() do
    Rider
    |> select([r], count(r.id))
    |> Repo.one()
  end

  def subscribe do
    Phoenix.PubSub.subscribe(BikeBrigade.PubSub, "riders")
  end

  defp broadcast({:error, _reason} = error, _event), do: error

  defp broadcast({:ok, struct}, event) do
    Phoenix.PubSub.broadcast(BikeBrigade.PubSub, "riders", {event, struct})
    {:ok, struct}
  end

  @default_preloads [:location]
  defp do_preload(results, opts) do
    preloads = Keyword.get(opts, :preload, @default_preloads)

    results
    |> Repo.preload(preloads)
  end
end
