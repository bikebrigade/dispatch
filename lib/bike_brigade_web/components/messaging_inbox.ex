defmodule BikeBrigadeWeb.Components.MessagingInbox do
  @moduledoc "Building blocks for the unified messaging inbox (`SmsMessageLive.Inbox`)."
  use BikeBrigadeWeb, :html

  alias BikeBrigadeWeb.Components.RiderDeliveriesComponent

  @doc """
  A campaign or bulk-message roster: the riders' individual conversations, the
  "Message everyone" drawer, and the selected rider's chat (the `:chat` slot) in a
  drawer over the roster.
  """
  attr :context, :any, required: true
  attr :rows, :list, required: true
  attr :rider, :any, required: true
  attr :tab, :string, required: true
  attr :close, :string, required: true
  attr :search, :string, required: true
  attr :mobile_open, :boolean, required: true
  attr :back_to_contexts, :string, required: true
  attr :uploads, :any, default: nil
  attr :everyone_open, :boolean, default: false
  attr :everyone_form, :any, required: true
  attr :confirm_send, :string, default: ""
  attr :wide_chat_xl, :boolean, default: false, doc: "widen the chat drawer on xl screens"
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
              :if={@context}
              id="message-everyone"
              type="button"
              phx-click="open_everyone"
              color={:white}
              size={:small}
            >
              Message everyone
            </.button>
          </div>
          <details :if={@context && @context.group} class="group mt-3">
            <summary class="flex cursor-pointer items-center gap-2 text-sm text-gray-600">
              <span class="shrink-0 text-xs font-medium text-gray-500">Original message</span>
              <span class="min-w-0 flex-1 truncate group-open:hidden">{@context.group.body}</span>
              <Heroicons.chevron_down class="ml-auto h-4 w-4 shrink-0 text-gray-400 group-open:rotate-180" />
            </summary>
            <p class="mt-2 whitespace-pre-line break-words text-sm text-gray-900">
              {@context.group.body}
            </p>
            <p class="mt-1 text-xs text-gray-500">
              Sent by {@context.group.creator} · {@context.group.created}
            </p>
          </details>
          <form id="roster-search-form" phx-change="search" class="mt-4">
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
          <div :for={row <- @rows} :key={row.rider.id} data-rider-id={row.rider.id}>
            <.link
              patch={row.link}
              class={[
                "flex items-start gap-3 p-5 hover:bg-gray-50",
                @rider && @rider.id == row.rider.id && "bg-indigo-50"
              ]}
            >
              <span class="flex h-9 w-9 shrink-0 items-center justify-center rounded-full bg-gray-100 text-xs font-medium text-gray-600">
                {rider_initials(row.rider.name)}
              </span>
              <div class="min-w-0 flex-1">
                <div class="flex min-w-0 flex-wrap items-center gap-2">
                  <span class={[
                    "text-sm text-indigo-600",
                    if(row.latest && row.latest.incoming,
                      do: "font-extrabold",
                      else: "font-semibold"
                    )
                  ]}>
                    {row.rider.name}
                  </span>
                  <span
                    :if={row[:deliveries]}
                    data-deliveries
                    title={RiderDeliveriesComponent.progress_label(row.deliveries)}
                    class={[
                      "inline-flex items-center gap-1 rounded-full px-2 py-0.5 text-xs font-medium tabular-nums ring-1 ring-inset",
                      if(RiderDeliveriesComponent.progress_complete?(row.deliveries),
                        do: "bg-green-50 text-green-700 ring-green-600/20",
                        else: "text-gray-600 ring-gray-300"
                      )
                    ]}
                  >
                    <RiderDeliveriesComponent.progress_chip_content progress={row.deliveries} />
                  </span>
                </div>
                <p class={[
                  "mt-2 break-words text-sm text-gray-600",
                  if(row.latest && row.latest.incoming, do: "font-extrabold", else: "font-medium")
                ]}>
                  {if row.latest,
                    do: String.slice(row.latest.body, 0, 220),
                    else: "No messages yet"}
                </p>
              </div>
              <Heroicons.chevron_right class="mt-1 h-4 w-4 shrink-0 text-gray-400" />
            </.link>
          </div>
          <p :if={@rows == []} class="p-6 text-sm text-gray-500">No riders match this view.</p>
        </div>
      </section>
      <div
        :if={@context && @everyone_open}
        id="everyone-drawer"
        class="absolute inset-0 z-30"
        phx-mounted={JS.transition({"ease-out duration-200", "opacity-0", "opacity-100"})}
        phx-remove={JS.hide(transition: {"ease-in duration-150", "opacity-100", "opacity-0"})}
      >
        <button
          type="button"
          aria-label="Close message everyone"
          class="absolute inset-0 w-full rounded-lg bg-gray-900/20"
          phx-click="close_everyone"
        />
        <section
          class="absolute inset-y-0 right-0 flex w-full min-h-0 flex-col overflow-y-auto rounded-lg border border-gray-200 bg-white shadow-xl md:w-2/3"
          aria-label="Message everyone"
          phx-mounted={JS.focus(to: "#group-message-body")}
          phx-window-keydown="close_everyone"
          phx-key="Escape"
        >
          <div class="flex items-start gap-3 border-b border-gray-200 px-4 py-5">
            <button
              type="button"
              aria-label="Back to conversations"
              class="flex-none pt-1"
              phx-click="close_everyone"
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
          <.form
            for={@everyone_form}
            id="group-message-form"
            class="p-5"
            phx-submit="message_group"
            phx-change="validate_everyone"
          >
            <.input
              field={@everyone_form[:body]}
              id="group-message-body"
              type="textarea"
              label="Message everyone"
              placeholder="Write to everyone…"
              maxlength="1600"
            />
            <.attachments :if={@uploads} upload={@uploads.media} />
            <div class="mt-2 flex flex-wrap items-center justify-between gap-2">
              <span class="text-xs text-gray-500">Delivered separately to each rider.</span><.button
                type="submit"
                size={:small}
                phx-disable-with="Sending…"
                data-confirm={@confirm_send != "" && @confirm_send}
              >Send to all {length(@context.ids)} riders</.button>
            </div>
          </.form>
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
          class={[
            "absolute inset-y-0 right-0 z-20 flex w-full min-h-0 flex-col rounded-lg border border-gray-200 bg-white shadow-xl",
            if(@wide_chat_xl, do: "md:w-2/3 xl:w-full", else: "md:w-2/3")
          ]}
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

  @doc "The inbox's header for a rider's conversation, with a back link to the list."
  attr :rider, :any, required: true
  attr :close, :string, required: true

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
          {rider_initials(@rider.name)}
        </span>
        <div class="min-w-0 flex-1">
          <div class="flex flex-wrap items-center gap-x-2 gap-y-1">
            <h3 class="pii break-words text-base font-semibold leading-6 text-gray-900">
              <.link
                navigate={~p"/riders/#{@rider}"}
                class="hover:text-indigo-600 hover:underline"
              >
                {rider_display_name(@rider)}
              </.link>
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
      </div>
    </div>
    """
  end

  @doc "Delivery progress under the rider header, for screens too narrow to show the panel."
  attr :progress, :map, required: true
  attr :open, :string, required: true, doc: "path that opens the deliveries panel"

  def deliveries_bar(assigns) do
    ~H"""
    <.link
      id="deliveries-bar"
      patch={@open}
      class="group flex shrink-0 items-center gap-2 border-b border-gray-200 bg-gray-50 px-4 py-2 text-sm sm:px-6 xl:hidden"
    >
      <Heroicons.check_circle
        :if={RiderDeliveriesComponent.progress_complete?(@progress)}
        mini
        class="h-5 w-5 text-green-600"
      />
      <Heroicons.shopping_bag
        :if={!RiderDeliveriesComponent.progress_complete?(@progress)}
        mini
        class="h-5 w-5 text-gray-400"
      />
      <span class="font-medium text-gray-900">Deliveries</span>
      <span class={[
        "ml-auto tabular-nums",
        if(RiderDeliveriesComponent.progress_complete?(@progress),
          do: "text-green-700",
          else: "text-gray-500"
        )
      ]}>
        {@progress.done} of {@progress.total} done
      </span>
      <Heroicons.chevron_right
        mini
        class="h-5 w-5 text-indigo-600 group-hover:translate-x-0.5 group-hover:text-indigo-700"
      />
    </.link>
    """
  end

  @doc """
  The photo attachment button and previews, styled like the conversation composer's
  (the file input itself is hidden behind the label).
  """
  attr :upload, :any, required: true, doc: "the `@uploads.media` upload config"

  def attachments(assigns) do
    ~H"""
    <div class="mt-3">
      <label
        for={@upload.ref}
        class="inline-flex cursor-pointer items-center gap-1.5 rounded border border-gray-300 bg-white px-2 py-1.5 text-xs font-medium text-gray-700 shadow-sm hover:bg-gray-50 focus-within:outline-none focus-within:ring-2 focus-within:ring-indigo-500 focus-within:ring-offset-2"
      >
        <.live_file_input upload={@upload} class="sr-only" />
        <Icons.tailwindui_upload_photo class="h-5 w-5" aria-hidden="true" /> Add photos
      </label>
      <div :if={@upload.entries != []} class="mt-3 grid grid-cols-3 gap-3">
        <figure :for={entry <- @upload.entries}>
          <.live_img_preview entry={entry} class="h-20 w-full rounded object-cover" />
          <figcaption class="mt-1 flex items-center gap-1 text-xs text-gray-500">
            <span class="min-w-0 flex-1 truncate">{entry.client_name}</span>
            <button
              type="button"
              phx-click="cancel_upload"
              phx-value-ref={entry.ref}
              aria-label={"Remove #{entry.client_name}"}
              class="text-gray-400 hover:text-gray-600"
            >
              <Heroicons.x_mark mini class="h-4 w-4" />
            </button>
          </figcaption>
          <.error :for={err <- upload_errors(@upload, entry)}>
            {upload_error_to_string(err)}
          </.error>
        </figure>
      </div>
    </div>
    """
  end
end
