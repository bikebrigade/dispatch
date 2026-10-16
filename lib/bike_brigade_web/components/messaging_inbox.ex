defmodule BikeBrigadeWeb.Components.MessagingInbox do
  use BikeBrigadeWeb, :html

  attr :context, :any, required: true
  attr :rows, :list, required: true
  attr :rider, :any, required: true
  attr :tab, :string, required: true
  attr :close, :string, required: true
  attr :search, :string, required: true
  attr :mobile_open, :boolean, required: true
  attr :back_to_contexts, :string, required: true
  attr :uploads, :any, default: nil
  slot :chat, required: true

  def merged_inbox(assigns) do
    ~H"""
    <div
      id="merged-inbox"
      class={[
        "relative h-[var(--inbox-workspace-height)] lg:h-auto min-h-0 min-w-0 flex-1 gap-4 lg:flex",
        if(@mobile_open, do: "flex", else: "hidden")
      ]}
    >
      <section class="min-w-0 flex-1 flex flex-col rounded-lg bg-white shadow">
        <div class="shrink-0 border-b border-gray-200 p-5">
          <.link
            id="back-to-contexts"
            patch={@back_to_contexts}
            class="mb-4 inline-flex items-center gap-1 text-sm text-indigo-600 lg:hidden"
          >
            <Heroicons.chevron_left class="h-5 w-5" />
            {if @tab == "campaigns", do: "Campaigns", else: "Bulk messages"}
          </.link>
          <div class="flex flex-wrap items-center justify-between gap-3">
            <div>
              <h2 class="text-lg font-semibold text-gray-900">
                {if @context,
                  do: @context.name,
                  else: if(@tab == "groups", do: "Choose a bulk message", else: "Choose a campaign")}
              </h2>
              <p class="mt-1 text-xs text-gray-500">
                {length(@rows)} riders · Individual conversations
              </p>
            </div>
            <.button
              :if={@tab == "campaigns" && @context}
              id="message-context-riders"
              type="button"
              phx-click={JS.show(to: "#everyone-drawer") |> JS.focus(to: "#group-message-body")}
              color={:white}
              size={:small}
            >
              Message everyone
            </.button>
            <.button
              :if={@tab == "groups" && @context}
              id="message-group-riders"
              type="button"
              phx-click={JS.show(to: "#everyone-drawer") |> JS.focus(to: "#group-message-body")}
              color={:white}
              size={:small}
            >
              Message everyone
            </.button>
          </div>
          <details :if={@context && @context.group} class="group mt-3">
            <summary class="flex cursor-pointer items-center gap-2 text-sm text-gray-600">
              <span class="shrink-0 text-xs font-medium text-gray-500">Original message</span>
              <span class="min-w-0 flex-1 truncate group-open:hidden">{@context.group["body"]}</span>
              <Heroicons.chevron_down class="ml-auto h-4 w-4 shrink-0 text-gray-400 group-open:rotate-180" />
            </summary>
            <p class="mt-2 whitespace-pre-line break-words text-sm text-gray-900">
              {@context.group["body"]}
            </p>
            <p class="mt-1 text-xs text-gray-500">
              Sent by {@context.group["creator"]} · {@context.group["created"]}
            </p>
          </details>
          <form phx-change="search" class="mt-4">
            <.input
              errors={[]}
              id="merged-search"
              name="search"
              value={@search}
              placeholder="Search for Riders"
              phx-debounce="150"
            />
          </form>
        </div>
        <div class="min-h-0 flex-1 overflow-y-auto divide-y divide-gray-100">
          <div :for={row <- @rows} data-rider-id={row.rider.id}>
            <.link
              patch={row.link}
              class={[
                "flex items-start gap-3 p-5 hover:bg-gray-50",
                @rider && @rider.id == row.rider.id && "bg-indigo-50"
              ]}
            >
              <span class="flex h-9 w-9 shrink-0 items-center justify-center rounded-full bg-gray-100 text-xs font-medium text-gray-600">
                {initials(row.rider.name)}
              </span>
              <div class="min-w-0 flex-1">
                <div class="flex flex-wrap justify-between gap-2">
                  <span class={[
                    "text-sm text-indigo-600",
                    if(row.latest && row.latest["incoming"],
                      do: "font-extrabold",
                      else: "font-semibold"
                    )
                  ]}>
                    {row.rider.name}
                  </span>
                  <span class="text-xs text-gray-400">
                    {if row.latest && row.latest["incoming"], do: "From rider", else: "From dispatch"}
                  </span>
                </div>
                <p class={[
                  "mt-2 break-words text-sm text-gray-600",
                  if(row.latest && row.latest["incoming"], do: "font-extrabold", else: "font-medium")
                ]}>
                  {if row.latest,
                    do: String.slice(row.latest["body"], 0, 220),
                    else: "No messages yet"}
                </p>
              </div>
              <Heroicons.chevron_right class="mt-1 h-4 w-4 shrink-0 text-gray-400" />
            </.link>
          </div>
          <p :if={@rows == []} class="p-6 text-sm text-gray-500">No riders match this view.</p>
        </div>
      </section>
      <div :if={@context} id="everyone-drawer" class="absolute inset-0 z-30 hidden">
        <button
          type="button"
          aria-label="Close message everyone"
          class="absolute inset-0 w-full rounded-lg bg-gray-900/20"
          phx-click={JS.hide(to: "#everyone-drawer")}
        />
        <section
          class="absolute inset-y-0 right-0 flex w-full min-h-0 flex-col overflow-y-auto rounded-lg border border-gray-200 bg-white shadow-xl md:w-2/3"
          aria-label="Message everyone"
          phx-window-keydown={JS.hide(to: "#everyone-drawer")}
          phx-key="Escape"
        >
          <div class="flex items-start gap-3 border-b border-gray-200 px-4 py-5">
            <button
              type="button"
              aria-label="Back to conversations"
              class="flex-none pt-1"
              phx-click={JS.hide(to: "#everyone-drawer")}
            >
              <Heroicons.chevron_left class="w-6 h-6 text-indigo-600" />
            </button>
            <div>
              <h3 class="text-lg font-medium text-gray-900">Message everyone</h3>
              <p class="mt-1 text-sm text-gray-500">
                {@context.name} · {length(@context.ids)} riders
              </p>
            </div>
          </div>
          <form
            id="group-message-form"
            class="p-5"
            phx-submit={JS.push("message_group")}
            phx-change="validate_everyone"
          >
            <.input
              errors={[]}
              id="group-message-body"
              type="textarea"
              name="body"
              value=""
              label="Message everyone"
              placeholder="Write to everyone…"
              required={is_nil(@uploads) or @uploads.media.entries == []}
              maxlength="1600"
            />
            <div :if={@uploads} class="mt-3">
              <.live_file_input upload={@uploads.media} class="text-sm text-gray-600" />
              <p :for={entry <- @uploads.media.entries} class="mt-1 text-xs text-gray-500">
                {entry.client_name}
              </p>
            </div>
            <div class="mt-2 flex flex-wrap items-center justify-between gap-2">
              <span class="text-xs text-gray-500">Delivered separately to each rider.</span><.button
                type="submit"
                size={:small}
                phx-disable-with="Sending…"
                data-confirm={BikeBrigade.SmsService.sending_confirmation_message()}
              >Send to all {length(@context.ids)} riders</.button>
            </div>
          </form>
        </section>
      </div>
      <%= if @rider do %>
        <.link
          patch={@close}
          aria-label="Close rider chat"
          class="absolute inset-0 z-10 rounded-lg bg-gray-900/20"
        >
          <span class="sr-only">Close rider chat</span>
        </.link>
        <section
          class="absolute inset-y-0 right-0 z-20 flex w-full min-h-0 flex-col rounded-lg border border-gray-200 bg-white shadow-xl md:w-2/3"
          id="inbox-chat-drawer"
          aria-label={"Chat with #{@rider.name}"}
          phx-window-keydown={JS.patch(@close)}
          phx-key="Escape"
        >
          {render_slot(@chat)}
        </section>
      <% end %>
    </div>
    """
  end

  attr :rider, :any, required: true
  attr :close, :string, required: true
  attr :profile, :boolean, default: false
  attr :tasks_link, :string, default: nil

  def rider_header(assigns) do
    ~H"""
    <div class="shrink-0 border-b border-gray-200 bg-white px-4 py-5 sm:px-6">
      <div class="flex items-center gap-3">
        <.link
          patch={@close}
          id="back-to-riders"
          aria-label="Back to conversations"
          class="-ml-2 flex h-11 w-11 shrink-0 items-center justify-center rounded-full text-indigo-600 hover:bg-indigo-50 focus:outline-none focus-visible:ring-2 focus-visible:ring-indigo-500"
        >
          <Heroicons.chevron_left class="w-6 h-6 text-indigo-600" />
        </.link>
        <span
          aria-hidden="true"
          class="flex h-10 w-10 shrink-0 items-center justify-center rounded-full bg-gray-100 text-sm font-medium text-gray-600"
        >
          {initials(@rider.name)}
        </span>
        <div class="min-w-0 flex-1">
          <div class="flex flex-wrap items-center gap-x-2 gap-y-1">
            <h3 class="pii break-words text-base font-semibold leading-6 text-gray-900">
              <.link
                :if={@profile}
                navigate={~p"/riders/#{@rider}"}
                class="hover:text-indigo-600 hover:underline"
              >
                {@rider.name || @rider.phone || "Unnamed rider"}
              </.link>
              <span :if={!@profile}>{@rider.name || @rider.phone || "Unnamed rider"}</span>
            </h3>
            <span
              :if={@rider.pronouns && @rider.pronouns != ""}
              class="rounded-md bg-gray-50 px-2 py-0.5 text-xs font-medium text-gray-500 ring-1 ring-inset ring-gray-200"
            >
              {@rider.pronouns}
            </span>
          </div>
          <div class="mt-1 flex min-w-0 items-center gap-1.5 text-sm text-gray-500">
            <Heroicons.device_phone_mobile mini class="w-4 h-4 flex-none text-gray-400" />
            <span class="pii break-all">{@rider.phone}</span>
          </div>
        </div>
        <.link
          :if={@tasks_link}
          navigate={@tasks_link}
          aria-label="Delivery details"
          title="Delivery details"
          class="flex h-11 w-11 shrink-0 items-center justify-center rounded-full text-gray-500 hover:bg-gray-50 hover:text-indigo-600"
        >
          <Heroicons.clipboard_document_list class="h-5 w-5" />
        </.link>
      </div>
    </div>
    """
  end

  defp initials(name),
    do:
      (name || "Unnamed rider")
      |> String.split()
      |> Enum.map(&String.first/1)
      |> Enum.take(2)
      |> Enum.join()
end
