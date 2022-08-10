defmodule BikeBrigadeWeb.ConnCase do
  @moduledoc """
  This module defines the test case to be used by
  tests that require setting up a connection.

  Such tests rely on `Phoenix.ConnTest` and also
  import other functionality to make it easier
  to build common data structures and query the data layer.

  Finally, if the test case interacts with the database,
  we enable the SQL sandbox, so changes done to the database
  are reverted at the end of every test. If you are using
  PostgreSQL, you can even run database tests asynchronously
  by setting `use BikeBrigadeWeb.ConnCase, async: true`, although
  this option is not recommended for other databases.
  """

  import BikeBrigade.Fixtures, only: [fixture: 1, fixture: 2]

  use ExUnit.CaseTemplate

  using do
    quote do
      # Import conveniences for testing with connections
      import Plug.Conn
      import Phoenix.ConnTest
      import BikeBrigadeWeb.ConnCase

      alias BikeBrigadeWeb.Router.Helpers, as: Routes

      # The default endpoint for testing
      @endpoint BikeBrigadeWeb.Endpoint
    end
  end

  setup tags do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(BikeBrigade.Repo)

    unless tags[:async] do
      Ecto.Adapters.SQL.Sandbox.mode(BikeBrigade.Repo, {:shared, self()})
    end

    {:ok, conn: Phoenix.ConnTest.build_conn()}
  end

  def login(%{conn: conn}) do
    user = fixture(:user, %{is_dispatcher: true})

    %{user: user, conn: login_user(conn, user)}
  end

  def create_program(%{}) do
    program = fixture(:program)
    %{program: program}
  end

  def create_campaign(%{}) do
    program = fixture(:program)
    campaign = fixture(:campaign, %{program_id: program.id})
    %{campaign: campaign, program: program}
  end

  def create_rider(%{}) do
    rider = fixture(:rider)
    %{rider: rider}
  end

  def create_opportunity(%{}) do
    program = fixture(:program)
    opportunity = fixture(:opportunity, %{program_id: program.id})
    %{opportunity: opportunity, program: program}
  end

  defp login_user(conn, user) do
    conn
    |> Phoenix.ConnTest.init_test_session(%{})
    |> BikeBrigadeWeb.Authentication.do_login(user)
  end
end
