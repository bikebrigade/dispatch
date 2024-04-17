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

  alias BikeBrigade.Accounts

  using do
    quote do
      # The default endpoint for testing
      @endpoint BikeBrigadeWeb.Endpoint

      use BikeBrigadeWeb, :verified_routes

      # Import conveniences for testing with connections
      import Plug.Conn
      import Phoenix.ConnTest
      import BikeBrigadeWeb.ConnCase
      import BikeBrigade.Fixtures
    end
  end

  setup tags do
    repo_pid = Ecto.Adapters.SQL.Sandbox.start_owner!(BikeBrigade.Repo, shared: not tags[:async])

    on_exit(fn ->
      Ecto.Adapters.SQL.Sandbox.stop_owner(repo_pid)

      # for pid <- BikeBrigade.Presence.fetchers_pids() do
      #   ref = Process.monitor(pid)
      #   assert_receive {:DOWN, ^ref, _, _, _}, 1000
      # end
    end)

    {:ok, conn: Phoenix.ConnTest.build_conn()}
  end

  # TODO: login_as_dispatcher
  def login(%{conn: conn}) do
    user = fixture(:user, %{is_dispatcher: true})

    %{user: user, conn: login_user(conn, user)}
  end

  def login_as_rider(%{conn: conn}) do
    rider = fixture(:rider)

    {:ok, user} = Accounts.create_user_for_rider(rider)

    %{conn: login_user(conn, user), user: user, rider: rider}
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

  def create_campaign_with_riders(%{}) do
    program = fixture(:program)
    {campaign, riders} = fixture(:campaign_with_riders, %{})
    %{campaign: campaign, program: program, riders: riders}
  end

  def create_rider(%{}) do
    rider = fixture(:rider)
    %{rider: rider}
  end

  def create_opportunity(%{program_attrs: program_attrs, opportunity_attrs: opportunity_attrs}) do
    program = fixture(:program, program_attrs)
    opportunity = fixture(:opportunity, Map.merge(%{program_id: program.id}, opportunity_attrs))
    %{opportunity: opportunity, program: program}
  end

  def create_opportunity(%{}) do
    program = fixture(:program)
    opportunity = fixture(:opportunity, %{program_id: program.id})
    %{opportunity: opportunity, program: program}
  end

  def login_user(conn, user) do
    conn
    |> Phoenix.ConnTest.init_test_session(%{})
    |> BikeBrigadeWeb.Authentication.do_login(user)
  end
end
