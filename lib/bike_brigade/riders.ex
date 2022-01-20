defmodule BikeBrigade.Riders do
  @moduledoc """
  The Riders context.
  """

  import Ecto.Query, warn: false
  alias BikeBrigade.Repo

  alias BikeBrigade.Riders.{Rider, Tag}
  alias BikeBrigade.Delivery.CampaignRider

  alias BikeBrigade.EctoPhoneNumber

  @doc """
  Returns the list of riders.

  ## Examples

      iex> list_riders()
      [%Rider{}, ...]

  """
  def list_riders do
    Repo.all(Rider)
  end

  def list_riders_with_tag(tag) do
    tag = Repo.get_by(Tag, name: tag) |> Repo.preload(:riders)
    if tag, do: tag.riders, else: []
  end

  def search_tags(search \\ "", limit \\ 10) do
    Tag
    |> where([u], ilike(u.name, ^"%#{search}%"))
    |> limit(^limit)
    |> Repo.all()
  end

  def search_riders(search \\ "", limit \\ 100) do
    name_search = dynamic([r], ilike(r.name, ^"%#{search}%"))
    email_search = dynamic([r], ilike(r.email, ^"%#{search}%"))
    phone_search = dynamic([r], ilike(r.phone, ^"%#{Regex.replace(~r/[^\d]/, search, "")}%"))

    where =
      if Regex.match?(~r/\d/, search) do
        dynamic(^name_search or ^email_search or ^phone_search)
      else
        dynamic(^name_search or ^email_search)
      end

    query =
      from r in Rider,
        where: ^where,
        left_join: cr in CampaignRider,
        on: cr.rider_id == r.id,
        limit: ^limit,
        group_by: r.id,
        order_by: [desc: count(cr.id)]

    Repo.all(query)
  end

  def search_riders_next(queries, {sort_order, sort_field})
      when sort_order in [:desc, :asc] do
    where =
      queries
      |> Enum.reduce(dynamic(true), fn
        {:name, search}, query ->
          dynamic(^query and ilike(as(:rider).name, ^"%#{search}%"))

        {:tag, tag}, query ->
          dynamic(^query and fragment("? = ANY(?)", ^tag, as(:tags).tags))
      end)

    order_by =
      case sort_field do
        :name ->
          [{sort_order, sort_field}]

        :last_active ->
          ["#{sort_order}_nulls_last": dynamic(as(:latest_campaign).delivery_start), asc: :name]
      end

    limit = 25

    latest_campaign_query =
      from cr in CampaignRider,
        where: cr.rider_id == parent_as(:rider).id,
        join: c in assoc(cr, :campaign),
        select: c,
        # TODO do we have an index here?
        order_by: [desc: c.delivery_date],
        limit: 1

    tags_query =
      from t in Tag,
        join: r in assoc(t, :riders),
        where: r.id == parent_as(:rider).id,
        select: %{tags: fragment("array_agg(?)", t.name)}

    query =
      from r in Rider,
        as: :rider,
        left_lateral_join: t in subquery(tags_query),
        as: :tags,
        left_lateral_join: l in subquery(latest_campaign_query),
        as: :latest_campaign,
        where: ^where,
        limit: ^limit,
        select_merge: %{latest_campaign_id: l.id},
        order_by: ^order_by

    Repo.all(query)
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
  def get_rider(id) do
    Repo.get(Rider, id)
  end

  def get_rider!(id) do
    Repo.get!(Rider, id)
  end

  def get_riders(ids) do
    Repo.all(from r in Rider, where: r.id in ^ids)
  end

  def get_rider_by_email!(email) do
    email = String.downcase(email)

    Rider
    |> Repo.get_by!(email: email)
  end

  def get_rider_by_email(email) do
    email = String.downcase(email)

    Rider
    |> Repo.get_by(email: email)
  end

  def get_rider_by_phone!(phone) do
    case EctoPhoneNumber.Canadian.cast(phone) do
      {:ok, phone} ->
        Repo.get_by!(Rider, phone: phone)

      {:error, err} ->
        raise EctoPhoneNumber.InvalidNumber, message: err
    end
  end

  def get_rider_by_phone(phone) do
    case BikeBrigade.EctoPhoneNumber.Canadian.cast(phone) do
      {:ok, phone} -> Repo.get_by(Rider, phone: phone)
      {:error, _err} -> nil
    end
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
  Deletes a rider.

  ## Examples

      iex> delete_rider(rider)
      {:ok, %Rider{}}

      iex> delete_rider(rider)
      {:error, %Ecto.Changeset{}}

  """
  def delete_rider(%Rider{} = rider) do
    Repo.delete(rider)
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
end
