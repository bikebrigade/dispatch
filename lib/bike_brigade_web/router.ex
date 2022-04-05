defmodule BikeBrigadeWeb.Router do
  use BikeBrigadeWeb, :router

  import BikeBrigade.Utils, only: [get_config: 1, dev?: 0]

  require Logger

  alias BikeBrigadeWeb.LiveHooks


  # Don't alert expired deliveries to honeybadger
  use Honeybadger.Plug
  def handle_errors(_conn, %{reason: %BikeBrigadeWeb.DeliveryExpiredError{}}), do: :ok
  def handle_errors(conn, err), do: super(conn, err)

  import BikeBrigadeWeb.Authentication,
    only: [
      require_authenticated_user: 2,
      redirect_if_user_is_authenticated: 2,
      get_user_from_session: 2
    ]

  @maintence_mode false

  pipeline :sessions do
    plug :fetch_session
    plug :get_user_from_session
  end

  pipeline :parse_request do
    plug Plug.Parsers,
      parsers: [:urlencoded, :multipart, :json],
      pass: ["*/*"],
      json_decoder: Phoenix.json_library()
  end

  pipeline :browser do
    plug :parse_request
    plug :accepts, ["html"]
    plug :sessions
    plug :fetch_live_flash
    plug :put_root_layout, {BikeBrigadeWeb.LayoutView, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug :check_maintence_mode
  end

  pipeline :api do
    plug :parse_request
    plug :accepts, ["json"]
  end

  scope "/analytics" do
    pipe_through [:sessions, :fetch_live_flash, :require_authenticated_user]

    forward "/", ReverseProxyPlug,
      upstream: get_config(:analytics_upstream),
      preserve_host_header: true,
      error_callback: &__MODULE__.log_reverse_proxy_error/1

    def log_reverse_proxy_error(error) do
      Logger.warn("ReverseProxyPlug network error: #{inspect(error)}")
    end
  end

  scope "/app", BikeBrigadeWeb do
    pipe_through [:browser]

    live "/delivery/:token", DeliveryLive.Show, :show
  end

  scope "/embed", BikeBrigadeWeb do
    pipe_through [:browser, :allow_framing]
    live "/calendar", CalendarLive.Index, :index
    live "/calendar/:id", CalendarLive.Index, :show

    if dev?() do
      get "/test", EmbedTestController, :index
    end
  end

  scope "/", BikeBrigadeWeb do
    pipe_through [:browser, :require_authenticated_user, :set_honeybadger_context]

    get "/", Plugs.Redirect, to: "/campaigns"

    live_session :dispatch, on_mount: LiveHooks.Authentication do
      live "/riders", RiderLive.Index, :index
      live "/riders/new", RiderLive.Index, :new
      live "/riders/:id/edit", RiderLive.Index, :edit
      live "/riders/message", RiderLive.Index, :message
      live "/riders/map", RiderLive.Index, :map # this is mostly used for testing!

      # Redirect for the old next url
      get "/riders-next",  Plugs.Redirect, to: "/riders", status: :moved_permanently

      live "/stats", StatsLive.Dashboard, :show
      live "/stats/leaderboard", StatsLive.Leaderboard, :show
      live "/campaigns", CampaignLive.Index, :index
      live "/campaigns/new", CampaignLive.Index, :new
      live "/campaigns/new2", CampaignLive.New, :new
      live "/campaigns/:id/edit", CampaignLive.Index, :edit
      live "/campaigns/:id/duplicate", CampaignLive.Index, :duplicate

      live "/campaigns/:id", CampaignLive.Show, :show
      live "/campaigns/:id/show/edit", CampaignLive.Show, :edit
      live "/campaigns/:id/messaging", CampaignLive.Show, :messaging
      live "/campaigns/:id/bulk_message", CampaignLive.Show, :bulk_message
      live "/campaigns/:id/add_rider", CampaignLive.Show, :add_rider
      live "/campaigns/:id/tasks/new", CampaignLive.Show, :new_task
      live "/campaigns/:id/tasks/:task_id/edit", CampaignLive.Show, :edit_task
      live "/campaigns/:id/printable/assignments", PrintableLive.CampaignAssignments, :index
      live "/campaigns/:id/printable/safety_check", PrintableLive.SafetyCheck, :index

      live "/opportunities", OpportunityLive.Index, :index
      live "/opportunities/new", OpportunityLive.Index, :new
      live "/opportunities/:id/edit", OpportunityLive.Index, :edit


      live "/items", ItemLive.Index, :index
      live "/items/new", ItemLive.Index, :new
      live "/items/:id/edit", ItemLive.Index, :edit

      live "/riders/:id", RiderLive.Show, :show
      live "/riders/:id/show/edit", RiderLive.Show, :edit

      live "/users", UserLive.Index, :index
      live "/users/new", UserLive.Index, :new
      live "/users/:id/edit", UserLive.Index, :edit

      live "/users/:id", UserLive.Show, :show
      live "/users/:id/show/edit", UserLive.Show, :edit

      live "/messages", SmsMessageLive.Index, :index
      live "/messages/new", SmsMessageLive.Index, :new
      live "/messages/:id", SmsMessageLive.Index, :show
      live "/messages/:id/tasks", SmsMessageLive.Index, :tasks

      live "/programs", ProgramLive.Index, :index
      live "/programs/new", ProgramLive.Index, :new
      live "/programs/:id/edit", ProgramLive.Index, :edit
      live "/programs/:id/items/new", ProgramLive.Index, :new_item
      live "/programs/:id/items/:item_id/edit", ProgramLive.Index, :edit_item

      live "/programs/:id", ProgramLive.Show, :show
      live "/programs/:id/show/edit", ProgramLive.Show, :edit
    end

    get "/stats/leaderboard/download", ExportStatsController, :leaderboard

    # TODO: this is unused
    get "/campaigns/download_stats", CampaignController, :download_stats

    get "/campaigns/:id/download_assignments", CampaignController, :download_assignments
    get "/campaigns/:id/download_results", CampaignController, :download_results

    post "/logout", Authentication, :logout
  end

  scope "/", BikeBrigadeWeb do
    pipe_through [:browser, :redirect_if_user_is_authenticated]

    live "/login", LoginLive, :index
    post "/login", Authentication, :login
  end

  scope "/", BikeBrigadeWeb do
    pipe_through [:api]

    get "/status", StatusController, :status
    get "/status/conn", StatusController, :conn
    post "/webhooks/twilio", Webhooks.Twilio, :incoming_sms
    post "/webhooks/twilio/status_callback", Webhooks.Twilio, :status_callback
    post "/webhooks/slack", Webhooks.Slack, :webhook
  end

  import Phoenix.LiveDashboard.Router

  scope "/" do
    pipe_through [:browser, :require_authenticated_user]
    live_dashboard "/dashboard", metrics: BikeBrigadeWeb.Telemetry, ecto_repos: [BikeBrigade.Repo]
  end

  defp set_honeybadger_context(conn, _opts) do
    user = conn.assigns[:current_user]

    if user do
      Honeybadger.context(user_id: user.id, user_email: user.email)
    end

    conn
  end

  defp check_maintence_mode(conn, _opts) do
    if @maintence_mode do
      conn
      |> put_status(:service_unavailable)
      |> text("Down for maintence, please check again in a few minutes")
      |> halt()
    else
      conn
    end
  end

  defp allow_framing(conn, _opts) do
    conn
    |> Plug.Conn.delete_resp_header("x-frame-options")
  end
end

defmodule BikeBrigadeWeb.Plugs.Redirect do
  import Plug.Conn, only: [halt: 1, put_status: 2]
  import Phoenix.Controller, only: [redirect: 2]

  @behaviour Plug

  @impl Plug
  def init(options) do
    options
  end

  @impl Plug
  def call(conn, options) do
    {status, options} = Keyword.pop(options, :status, :found)

    conn
    |> put_status(status)
    |> redirect(options)
    |> halt()
  end
end
