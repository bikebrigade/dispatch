defmodule BikeBrigadeWeb.Components.SMSMessageListComponent do
  use Phoenix.Component
  use BikeBrigadeWeb, :html
  alias BikeBrigade.Messaging.SmsMessage

  def preview_message(%SmsMessage{body: body}) when not is_nil(body) do
    if String.length(body) > 30 do
      String.slice(body, 0, 30) <> "..."
    else
      body
    end
  end

  def preview_message(%SmsMessage{media: media}) when length(media) > 0 do
    "Attachment: #{length(media)} media"
  end

  def preview_message(_), do: "unknown message"

  attr :sms_list, :any, required: true

  @doc """
  A helper component to determine where clicking on a rider in an sms list takes us
  we render the sms list in different capacities; this allows deciding to which sms
  instance clicking a rider would take us to.
  """
  def message_link(assigns) do
    route =
      case assigns.sms_list do
        {"/messages"} ->
          ~p"/messages/#{assigns.rider_id}"

        {"/campaigns", campaign_id} ->
          ~p"/campaigns/#{campaign_id}/messaging/riders/#{assigns.rider_id}"
      end

    assigns = assign(assigns, :route, route)

    ~H"""
    <.link
      patch={@route}
      class=" px-2 py-1 border-b hover:bg-gray-100 block transition duration-150 ease-in-out  focus:outline-none"
    >
      <%= render_slot(@inner_block) %>
    </.link>
    """
  end

  @doc """
  Renders a list of sms messages

  ## Examples
      <.sms_message_list
      conversations={@conversations}
      >
  """

  attr :conversations, :list, required: true
  attr :sms_list, :any, required: true

  def sms_message_list(assigns) do
    ~H"""
    <ul
      class="flex-grow-0 h-full max-h-full overflow-y-auto scrolling-touch overscroll-contain"
      id="conversation-list"
      phx-hook="ConversationList"
      phx-update="append"
    >
      <li
        :for={{rider, last_message} <- @conversations}
        id={"conversation-list-item:#{rider.id}"}
        data-rider-id={rider.id}
      >
        <.message_link sms_list={@sms_list} rider_id={rider.id}>
          <div class="flex items-center px-2 py-2">
            <div class="flex items-center flex-1 min-w-0">
              <div class="flex-shrink-0 hidden mr-4 lg:block">
                <img class="w-10 h-10 rounded-full" src={gravatar(rider.email)} alt="" />
              </div>

              <%= if last_message do %>
                <div class="flex-1 min-w-0">
                  <div class="flex flex-col">
                    <div class={[
                      "pii",
                      "text-sm leading-5 text-indigo-600 truncate",
                      if(last_message.from == rider.phone,
                        do: "font-extrabold",
                        else: "font-semibold"
                      )
                    ]}>
                      <%= rider.name %>
                    </div>
                    <div class="text-xs text-gray-500 font-medium">
                      <%= datetime(last_message.sent_at) %>
                    </div>
                  </div>
                  <div class={[
                    "flex items-center mt-2 text-sm leading-5 text-gray-500",
                    if(last_message.from == rider.phone, do: "font-extrabold", else: "font-medium")
                  ]}>
                    <span class="truncate">
                      <%= preview_message(last_message) %>
                    </span>
                  </div>
                </div>
              <% else %>
                <div class="flex-1 min-w-0">
                  <div class={["pii", "text-sm leading-5 text-indigo-600 truncate"]}>
                    <%= rider.name %>
                  </div>
                  <div class={["flex items-center mt-2 text-sm leading-5 text-gray-500"]}>
                    <span class="truncate">
                      No messages yet.
                    </span>
                  </div>
                </div>
              <% end %>
            </div>
          </div>
        </.message_link>
      </li>
    </ul>
    """
  end
end
