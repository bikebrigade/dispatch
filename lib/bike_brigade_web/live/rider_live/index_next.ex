defmodule BikeBrigadeWeb.RiderLive.IndexNext do
  use BikeBrigadeWeb, :live_view

  alias BikeBrigade.Repo
  alias BikeBrigade.Riders
  alias BikeBrigade.Delivery
  alias BikeBrigade.LocalizedDateTime

  @impl Phoenix.LiveView
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:riders, fetch_riders())
     |> assign(:page, :riders)
     |> assign(:selected, MapSet.new())}
  end

  @impl Phoenix.LiveView

  def handle_event(
        "select",
        %{"_target" => ["selected", "all"], "selected" => %{"all" => select_all}},
        socket
      ) do
    selected =
      case select_all do
        "true" ->
          for r <- socket.assigns.riders, into: MapSet.new(), do: r.id

        "false" ->
          MapSet.new()
      end

    {:noreply, assign(socket, :selected, selected)}
  end

  def handle_event(
        "select",
        %{"_target" => ["selected", id], "selected" => selected_params},
        socket
      ) do
    selected =
      case selected_params[id] do
        "true" ->
          MapSet.put(socket.assigns.selected, String.to_integer(id))

        "false" ->
          MapSet.delete(socket.assigns.selected, String.to_integer(id))
      end

    {:noreply, assign(socket, :selected, selected)}
  end

  def handle_event(
        "select",
        %{"_target" => ["selected", "all"], "selected" => selected_params},
        socket
      ) do
    %{opportunities: opportunities} = socket.assigns

    selected =
      case selected_params["all"] do
        "true" -> Enum.map(opportunities, & &1.id) |> MapSet.new()
        "false" -> MapSet.new()
      end

    {:noreply, assign(socket, :selected, selected)}
  end

  def handle_event("bulk-message", _params, socket) do
    rider_ids = socket.assigns.selected |> MapSet.to_list()

    {:noreply,
     push_redirect(socket,
       to: Routes.sms_message_index_path(socket, :new, r: rider_ids),
       replace: false
     )}
  end

  defp fetch_riders() do
    Riders.search_riders()
    |> Repo.preload(:tags)
  end

  defp latest_campaign_date(assigns) do
    assigns = assign(assigns, :date, Delivery.latest_campaign_date(assigns.rider))
    ~H"""
    <%= if @date do %>
      <%=  @date |> LocalizedDateTime.to_date() |> Calendar.strftime("%b %-d, %Y") %>
    <% end %>
    """
  end

  @impl Phoenix.LiveView
  def render(assigns) do
    ~H"""
    <div>
      <div class="flex justify-between">
        <input type="text" phx-keydown="search-riders" phx-debounce="100"
          value={}
          class="block w-2/3 px-3 py-2 placeholder-gray-400 border-gray-300 rounded-md shadow-sm focus:ring-indigo-500 focus:border-indigo-500 sm:text-sm"
          placeholder="Name, email, phone, tag, neighborhood" />
        <C.button phx-click="bulk-message">Bulk Message</C.button>
      </div>
      <form id="selected" phx-change="select"></form>
      <UI.table rows={@riders} class="mt-2">
        <:th class="text-center" padding="px-3">
        <%= checkbox :selected, :all,
          form: "selected",
          value: Enum.count(@selected) == Enum.count(@riders),
          class: "w-4 h-4 text-indigo-600 border-gray-300 rounded focus:ring-indigo-500" %>
        </:th>
        <:th padding="px-3">
          Name
        </:th>
        <:th>
          Location
        </:th>
        <:th>
          Tags
        </:th>
        <:th>
          Last Active
        </:th>

        <:td let={rider} class="text-center" padding="px-3">
          <%= checkbox :selected, "#{rider.id}",
            form: "selected",
            value: MapSet.member?(@selected, rider.id),
            class: "w-4 h-4 text-indigo-600 border-gray-300 rounded focus:ring-indigo-500" %>
        </:td>
        <:td let={rider} padding="px-3">
          <%= live_redirect to: Routes.rider_show_path(@socket, :show, rider), class: "link" do %>
            <%= rider.name %><span class="ml-1 text-xs lowercase ">(<%= rider.pronouns %>)</span>
          <% end %>
        </:td>
        <:td let={rider}>
          <%= rider.location_struct.neighborhood %>
        </:td>
        <:td let={rider}>
          <%= rider.tags |> Enum.map(& &1.name) |> Enum.join(",") %>
        </:td>
        <:td let={rider}>
          <.latest_campaign_date rider={rider}/>
        </:td>
      </UI.table>
    </div>
    """
  end
end
