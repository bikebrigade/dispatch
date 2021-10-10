defmodule BikeBrigade.Accounts do
  @moduledoc """
  The Accounts context.
  """

  import Ecto.Query, warn: false
  alias BikeBrigade.Repo

  alias BikeBrigade.Accounts.User

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


  @doc """
  Creates a user.

  ## Examples

      iex> create_user(%{field: value})
      {:ok, %User{}}

      iex> create_user(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_user(attrs \\ %{}) do
    %User{}
    |> User.changeset(attrs)
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
end
