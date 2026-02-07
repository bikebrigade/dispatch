defmodule BikeBrigade.Accounts do
  @moduledoc """
  The Accounts context.
  """

  import Ecto.Query, warn: false
  alias BikeBrigade.Repo

  alias BikeBrigade.Accounts.User
  alias BikeBrigade.Riders.Rider

  @doc """
  Returns the list of users.

  ## Examples

      iex> list_users()
      [%User{}, ...]

  """
  def list_users do
    Repo.all(User)
  end

  @doc """
  Gets a single user.

  Returns nil if the user doesn't exist.

  ## Examples

      iex> get_user(123)
      %User{}

      iex> get_user!(456)
      nil

  """
  def get_user(id), do: Repo.get(User, id)

  @doc """
  Gets a single user by phone number

  Returns `nil` if the User does not exist.

  ## Examples

      iex> get_user_by_hone(123)
      %User{}

      iex> get_user!(456)
      ** (Ecto.NoResultsError)

  """
  def get_user_by_phone(phone) do
    Repo.get_by(User, phone: phone)
  end

  @doc "Get a list of users from a list of ids"
  def get_users(ids) do
    query =
      from u in User,
        where: u.id in ^ids

    Repo.all(query)
  end

  @doc "Search for users by name"
  def search_users(search) do
    query =
      from r in User,
        where: ilike(r.name, ^"%#{search}%")

    Repo.all(query)
  end

  @per_page 20

  @doc """
  Returns a paginated, filterable list of users.

  Options:
    - `:search` - filter by name (ilike), default ""
    - `:dispatchers_only` - when true, only show dispatchers, default true
    - `:page` - 1-indexed page number, default 1
  """
  def list_users_paginated(opts \\ %{}) do
    search = Map.get(opts, :search, "")
    dispatchers_only = Map.get(opts, :dispatchers_only, true)
    page = Map.get(opts, :page, 1)
    offset = (page - 1) * @per_page

    query = from(u in User, order_by: u.name)

    query =
      if search != "" do
        from(u in query, where: ilike(u.name, ^"%#{search}%"))
      else
        query
      end

    query =
      if dispatchers_only do
        from(u in query, where: u.is_dispatcher == true)
      else
        query
      end

    total = Repo.aggregate(query, :count)
    users = Repo.all(from(u in query, offset: ^offset, limit: ^@per_page))

    {users, total}
  end

  @doc """
  Creates a user (using the admin changeset).
  """
  def create_user_as_admin(attrs \\ %{}) do
    %User{}
    |> User.admin_changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Creates a user for a given rider
  """
  def create_user_for_rider(%Rider{} = rider) do
    attrs = %{rider_id: rider.id, name: rider.name, email: rider.email, phone: rider.phone}

    %User{}
    |> User.admin_changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a user.

  ## Examples

      iex> update_user(user, %{field: new_value})
      {:ok, %User{}}

      iex> update_user(user, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_user(%User{} = user, attrs) do
    user
    |> User.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Updates a user using the admin changeset.
  """
  def update_user_as_admin(%User{} = user, attrs) do
    user
    |> User.admin_changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a user.

  ## Examples

      iex> delete_user(user)
      {:ok, %User{}}

      iex> delete_user(user)
      {:error, %Ecto.Changeset{}}

  """
  def delete_user(%User{} = user) do
    Repo.delete(user)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking user changes.

  ## Examples

      iex> change_user(user)
      %Ecto.Changeset{data: %User{}}

  """
  def change_user(%User{} = user, attrs \\ %{}) do
    User.changeset(user, attrs)
  end

  def get_dispatcher_phone_numbers() do
    query =
      from u in User,
        select: u.phone

    Repo.all(query)
  end
end
