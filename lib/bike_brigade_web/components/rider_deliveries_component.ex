defmodule BikeBrigadeWeb.Components.RiderDeliveriesComponent do
  @moduledoc """
  A rider's recent deliveries (see `Delivery.latest_campaign_tasks/1`), shown next
  to their conversation so dispatchers can look up and update tasks while chatting.
  """
  use BikeBrigadeWeb, :live_component

  alias BikeBrigade.Delivery
  alias BikeBrigadeWeb.CampaignHelpers

  import BikeBrigadeWeb.CampaignHelpers, only: [request_type: 1]

  @doc "Delivery progress as `%{done: done, total: total}`, or nil when there are no deliveries."
  def progress(campaigns) when is_list(campaigns) do
    tasks = Enum.flat_map(campaigns, & &1.tasks)
    progress(length(tasks), Enum.count(tasks, &delivered?/1))
  end

  def progress(0, _done), do: nil
  def progress(total, done), do: %{done: done, total: total}

  def progress_label(%{done: done, total: 1}), do: "#{done} of 1 delivery done"
  def progress_label(%{done: done, total: total}), do: "#{done} of #{total} deliveries done"

  def progress_complete?(%{done: done, total: total}), do: done == total

  attr :progress, :map, required: true

  @doc "Compact progress like \"1/3\", with a check once everything is delivered."
  def progress_chip_content(assigns) do
    ~H"""
    <Heroicons.check_circle :if={progress_complete?(@progress)} mini class="h-3.5 w-3.5" />
    <Heroicons.shopping_bag :if={!progress_complete?(@progress)} mini class="h-3.5 w-3.5" />
    <span aria-hidden="true">{@progress.done}/{@progress.total}</span>
    <span class="sr-only">{progress_label(@progress)}</span>
    """
  end

  @impl true
  def handle_event("toggle_delivered", %{"task_id" => task_id}, socket) do
    # The parent LiveView refreshes from the :task_updated (or :task_deleted) broadcast,
    # so a task deleted since this panel rendered is simply skipped.
    if task = Delivery.get_task(task_id) do
      status = if delivered?(task), do: :pending, else: :completed
      Delivery.update_task(task, %{delivery_status: status})
    end

    {:noreply, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <section
      id={@id}
      aria-label={"Deliveries for #{@rider.name}"}
      class={["min-h-0 flex-col rounded-lg bg-white shadow", @class]}
    >
      <div class="flex shrink-0 items-center gap-3 border-b border-gray-200 px-4 py-5">
        <.link
          patch={@close}
          aria-label="Back to conversation"
          class="-ml-2 flex h-11 w-11 shrink-0 items-center justify-center rounded-full text-indigo-600 hover:bg-indigo-50 xl:hidden"
        >
          <Heroicons.chevron_left class="h-6 w-6" />
        </.link>
        <div class="min-w-0">
          <h3 class="text-base font-semibold text-gray-900">Deliveries</h3>
          <p class="text-xs text-gray-500">Yesterday and today</p>
        </div>
      </div>
      <div class="min-h-0 flex-1 divide-y divide-gray-200 overflow-y-auto">
        <div :for={campaign <- @campaigns} class="space-y-3 p-4">
          <div class="flex items-start gap-2">
            <div class="min-w-0 flex-1">
              <.link
                navigate={~p"/campaigns/#{campaign}"}
                class="text-sm font-semibold text-indigo-600 hover:text-indigo-500"
              >
                {CampaignHelpers.name(campaign)}
              </.link>
              <p class="mt-0.5 text-xs text-gray-500">
                {format_date(campaign.delivery_start)} · {campaign.rider_pickup_window ||
                  CampaignHelpers.pickup_window(campaign)} · {Enum.count(
                  campaign.tasks,
                  &delivered?/1
                )} of {length(campaign.tasks)} delivered
              </p>
            </div>
          </div>

          <ul class="divide-y divide-gray-100">
            <li
              :for={task <- campaign.tasks}
              id={"rider-delivery-#{task.id}"}
              class="flex items-start gap-3 py-3"
            >
              <button
                type="button"
                role="checkbox"
                aria-checked={to_string(delivered?(task))}
                aria-label={"Delivered to #{task.dropoff_name}"}
                phx-click={JS.push("toggle_delivered", value: %{task_id: task.id}, target: @myself)}
                class={[
                  "mt-0.5 flex h-6 w-6 shrink-0 items-center justify-center rounded-full ring-1 ring-inset",
                  if(delivered?(task),
                    do: "bg-green-600 text-white ring-green-600",
                    else: "text-transparent ring-gray-300 hover:text-gray-300 hover:ring-green-600"
                  )
                ]}
              >
                <Heroicons.check mini class="h-4 w-4" />
              </button>
              <div class={["min-w-0 flex-1 text-sm", delivered?(task) && "text-gray-400"]}>
                <p class={[
                  "pii font-medium",
                  if(delivered?(task), do: "line-through", else: "text-gray-900")
                ]}>
                  {task.dropoff_name}
                </p>
                <p class="pii">{task.dropoff_location.address}</p>
                <p class="text-xs text-gray-500">
                  {request_type(task)}
                </p>
                <p :if={task.delivery_instructions} class="mt-1 text-xs text-gray-500">
                  {task.delivery_instructions}
                </p>
              </div>
            </li>
          </ul>
        </div>
      </div>
    </section>
    """
  end

  defp delivered?(task), do: task.delivery_status == :completed
end
