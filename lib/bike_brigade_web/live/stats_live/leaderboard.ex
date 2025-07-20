defmodule BikeBrigadeWeb.StatsLive.Leaderboard do
  use BikeBrigadeWeb, :live_view
  alias BikeBrigadeWeb.StatsLive.NavComponent
  alias BikeBrigade.Stats

  alias BikeBrigade.LocalizedDateTime

  alias BikeBrigade.Riders

  defmodule Options do
    # This pattern is from  https://mattpruitt.com/articles/phoenix-forms-with-ecto-embedded-schema
    # evaluating about using it more
    use BikeBrigade.Schema
    import Ecto.Changeset
    import EctoEnum

    defenum(SortBy,
      rider_name: "rider_name",
      campaigns: "campaigns",
      deliveries: "deliveries",
      distance: "distance"
    )

    defenum(SortOrder, asc: "asc", desc: "desc")
    defenum(Period, all_time: "all_time", select: "select")

    @required [:sort_by, :sort_order, :period]
    @attributes @required ++ [:start_date, :end_date]
    @primary_key false

    embedded_schema do
      field :sort_by, SortBy, default: :campaigns
      field :sort_order, SortOrder, default: :desc
      field :period, Period, default: :all_time
      field :start_date, :date
      field :end_date, :date
    end

    def default() do
      # Default dates need to be computed at runtime so we have to the date computation here
      end_date = LocalizedDateTime.today()
      start_date = Date.add(end_date, -7)
      %__MODULE__{start_date: start_date, end_date: end_date}
    end

    def changeset(options, attrs \\ %{}) do
      cast(options, attrs, @attributes)
      |> validate_required(@required)
      |> maybe_move_end_date()
    end

    def update(options, attrs) do
      options
      |> changeset(attrs)
      |> apply_action(:update)
    end

    defp maybe_move_end_date(changeset) do
      with {_, start_date} <- fetch_field(changeset, :start_date),
           {_, end_date} <- fetch_field(changeset, :end_date),
           :lt <- Date.compare(end_date, start_date) do
        put_change(changeset, :end_date, start_date)
      else
        _ -> changeset
      end
    end
  end

  @impl Phoenix.LiveView
  def mount(_params, _session, socket) do
    options = Options.default()

    current_rider =
      if socket.assigns.current_user.rider_id,
        do: Riders.get_rider!(socket.assigns.current_user.rider_id)

    {:ok,
     socket
     |> assign(:page, :leaderboard)
     |> assign(:page_title, "Leaderboard")
     |> assign(:options, options)
     |> assign(:current_rider, current_rider)
     |> assign(:show_anonymous_riders?, false)
     |> assign_stats()}
  end

  @impl Phoenix.LiveView
  def handle_params(_params, _url, socket) do
    {:noreply, socket}
  end

  @impl Phoenix.LiveView
  def handle_event("sort", %{"field" => field, "order" => order}, socket) do
    socket =
      case Options.update(socket.assigns.options, %{sort_by: field, sort_order: order}) do
        {:ok, options} ->
          assign(socket, :options, options) |> assign_stats()

        {:error, _err} ->
          put_flash(socket, :error, "Invalid options selected")
      end

    {:noreply, socket}
  end

  @impl Phoenix.LiveView
  def handle_event("update_options", %{"options" => options_params}, socket) do
    socket =
      case Options.update(socket.assigns.options, options_params) do
        {:ok, options} -> assign(socket, :options, options) |> assign_stats()
        {:error, _} -> put_flash(socket, :error, "Invalid options selected")
      end

    {:noreply, socket}
  end

  @impl Phoenix.LiveView
  def handle_event("toggle_all_riders_anonymity", _params, socket) do
    if socket.assigns.current_user.is_dispatcher do
      {:noreply,
       socket |> assign(:show_anonymous_riders?, !socket.assigns.show_anonymous_riders?)}
    else
      {:noreply, socket}
    end
  end

  @impl Phoenix.LiveView
  def handle_event("toggle_rider_anon", _params, socket) do
    %{current_rider: current_rider} = socket.assigns

    socket =
      case Riders.update_rider(current_rider, %{
             anonymous_in_leaderboard: !current_rider.anonymous_in_leaderboard
           }) do
        {:ok, rider} ->
          socket
          |> assign(:current_rider, rider)
          |> assign_stats()

        {:error, _error} ->
          socket |> put_flash(:error, "Unable to update leaderboard visibility")
      end

    {:noreply, socket}
  end

  defp assign_stats(socket) do
    stats =
      case socket.assigns.options do
        %Options{period: :all_time, sort_by: sort_by, sort_order: sort_order} ->
          Stats.rider_leaderboard(sort_by, sort_order)

        %Options{
          period: :select,
          sort_by: sort_by,
          sort_order: sort_order,
          start_date: start_date,
          end_date: end_date
        } ->
          Stats.rider_leaderboard(sort_by, sort_order, start_date, end_date)
      end

    socket
    |> assign(:stats, stats)
  end

  defp download_path(options) do
    %{
      period: period,
      sort_by: sort_by,
      sort_order: sort_order,
      start_date: start_date,
      end_date: end_date
    } = options

    params =
      case period do
        :all_time ->
          %{
            sort_by: options.sort_by,
            sort_order: options.sort_order
          }

        :select ->
          %{
            sort_by: sort_by,
            sort_order: sort_order,
            start_date: start_date,
            end_date: end_date
          }
      end

    ~p"/stats/leaderboard/download?#{params}"
  end

  defp display_rider(
         %{
           rider: rider,
           current_rider: current_rider,
           override_anonymity: override_anonymity
         } = assigns
       ) do
    is_anonymous =
      if override_anonymity, do: !override_anonymity, else: rider.anonymous_in_leaderboard

    is_current_rider = current_rider && rider.id == current_rider.id

    name =
      cond do
        is_anonymous && is_current_rider -> "Anonymous (you)"
        is_anonymous -> "Anonymous"
        true -> rider.name
      end

    class = if is_current_rider, do: "bg-yellow-200 p-1", else: "p-1"

    assigns =
      assign(assigns,
        name: name,
        class: class,
        is_anonymous: is_anonymous,
        is_current_rider: is_current_rider
      )

    ~H"""
    <div class="flex flex-col sm:flex-row">
      <span class={@class}>{@name}</span>
      <.button
        :if={@is_current_rider}
        size={:xsmall}
        color={:secondary}
        class="mt-1 ml-0 sm:ml-1 sm:mt-0"
        phx-click="toggle_rider_anon"
      >
        {if @is_anonymous, do: "Show", else: "Hide"} me
      </.button>
    </div>
    """
  end
end
