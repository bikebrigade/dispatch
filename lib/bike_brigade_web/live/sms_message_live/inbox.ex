defmodule BikeBrigadeWeb.SmsMessageLive.Inbox do
  use BikeBrigadeWeb, :live_view
  alias BikeBrigade.{Messaging, Riders, Delivery, Presence}
  alias BikeBrigade.Messaging.Inbox
  alias BikeBrigadeWeb.Components.ConversationComponent
  import BikeBrigadeWeb.Components.SMSMessageListComponent
  import BikeBrigadeWeb.Components.MessagingInbox, only: [merged_inbox: 1]
  import BikeBrigadeWeb.SmsMessageLive.Index, only: [currently_viewing: 1]

  def mount(_params, _session, socket) do
    if Inbox.enabled?(socket.assigns.current_user) do
      if connected?(socket),
        do:
          (
            Messaging.subscribe()
            Delivery.subscribe()
            BikeBrigadeWeb.Endpoint.subscribe("messaging_presence")
            Presence.track(self(), "messaging_presence", socket.assigns.current_user.id, %{})
          )

      {:ok,
       socket
       |> allow_upload(:media, accept: ~w(.gif .png .jpg .jpeg), max_entries: 10)
       |> assign(
         page: :messages,
         page_title: "Messages",
         wide_content: true,
         modal: false,
         save_group: false,
         bulk_ids: [],
         bulk_form: to_form(%{"body" => "", "name" => ""}),
         error: nil,
         presence: Presence.list("messaging_presence"),
         others_present:
           others_present(socket.assigns.current_user, Presence.list("messaging_presence"))
       )}
    else
      {:ok, redirect(socket, to: ~p"/messages")}
    end
  end

  def handle_params(params, _, socket) do
    if Inbox.enabled?(socket.assigns.current_user) do
      {:noreply, socket |> assign(params: params, modal: params["compose"] == "new") |> refresh()}
    else
      {:noreply, socket}
    end
  end

  def handle_event("filters", params, socket) do
    {:noreply,
     push_patch(socket,
       to:
         inbox_path(socket.assigns, %{"mine" => params["mine"], "context" => nil, "rider" => nil})
     )}
  end

  def handle_event("search", %{"search" => search}, socket) do
    {:noreply,
     push_patch(socket, to: inbox_path(socket.assigns, %{"search" => search}), replace: true)}
  end

  def handle_event("bulk", _, socket) do
    socket =
      Enum.reduce(socket.assigns.uploads.media.entries, socket, fn entry, socket ->
        cancel_upload(socket, :media, entry.ref)
      end)

    {:noreply,
     assign(socket,
       modal: true,
       bulk_ids: [],
       save_group: false,
       error: nil,
       bulk_form: to_form(%{"body" => "", "name" => ""})
     )}
  end

  def handle_event("close_bulk", _, socket), do: {:noreply, assign(socket, modal: false)}

  def handle_event("validate_bulk", params, socket) do
    {:noreply,
     assign(socket,
       bulk_form: to_form(Map.take(params, ["body", "name"])),
       save_group: params["save_group"] == "true",
       error: nil
     )}
  end

  def handle_event("validate_everyone", _, socket), do: {:noreply, socket}

  def handle_event("cancel_upload", %{"ref" => ref}, socket),
    do: {:noreply, cancel_upload(socket, :media, ref)}

  def handle_event("send_bulk", params, socket) do
    # Recipient IDs come from the server-owned picker state, never from an arbitrary context URL.
    opts = [
      save: params["save_group"] == "true",
      name: params["name"] || "",
      media: socket.assigns.uploads.media.entries
    ]

    result =
      with :ok <- Inbox.validate(socket.assigns.bulk_ids, params["body"], opts) do
        Inbox.send(
          socket.assigns.current_user,
          socket.assigns.bulk_ids,
          params["body"],
          Keyword.put(opts, :media, consume_media(socket))
        )
      end

    case result do
      {:ok, result} ->
        socket = finish_send(socket, result) |> assign(modal: false)

        socket =
          if result.group,
            do:
              push_patch(socket,
                to:
                  inbox_path(socket.assigns, %{
                    "tab" => "groups",
                    "context" => result.group.id,
                    "rider" => nil
                  })
              ),
            else: socket

        {:noreply, socket}

      {:error, error} ->
        {:noreply, assign(socket, error: error_text(error))}
    end
  end

  def handle_event("message_group", %{"body" => body}, %{assigns: %{context: context}} = socket)
      when not is_nil(context) do
    # Always use the complete server-resolved roster, even when search narrows the visible list.
    result =
      with :ok <- Inbox.validate(context.ids, body, media: socket.assigns.uploads.media.entries) do
        opts = [media: consume_media(socket)]

        opts =
          if socket.assigns.tab == "campaigns",
            do: Keyword.put(opts, :campaign_id, context.id),
            else: opts

        Inbox.send(socket.assigns.current_user, context.ids, body, opts)
      end

    case result do
      {:ok, result} -> {:noreply, finish_send(socket, result)}
      {:error, error} -> {:noreply, put_flash(socket, :error, error_text(error))}
    end
  end

  def handle_info({:rider_selection_changed, "inbox-rider-select", riders}, socket),
    do: {:noreply, assign(socket, bulk_ids: Enum.map(riders, & &1.id))}

  def handle_info({event, message}, socket) when event in [:message_created, :message_updated] do
    if socket.assigns.rider && socket.assigns.rider.id == message.rider_id do
      send_update(ConversationComponent, id: message.rider_id, conversation: [message])
    end

    {:noreply, refresh(socket)}
  end

  def handle_info(%{event: "presence_diff", payload: %{joins: joins, leaves: leaves}}, socket) do
    presence = socket.assigns.presence |> Map.merge(joins) |> Map.drop(Map.keys(leaves))

    {:noreply,
     assign(socket,
       presence: presence,
       others_present: others_present(socket.assigns.current_user, presence)
     )}
  end

  def handle_info(_, socket), do: {:noreply, refresh(socket)}

  defp others_present(current_user, presence) do
    for {_, %{user: user}} <- presence, user && user.id != current_user.id, do: user
  end

  defp finish_send(socket, result) do
    socket = refresh(socket)

    if result.failed == [] do
      socket
      |> put_flash(:info, "Sent to #{result.sent} riders.")
      |> push_event("inbox:sent", %{})
    else
      names = Enum.map_join(result.failed, ", ", &(&1.name || &1.phone || "Unnamed rider"))

      put_flash(
        socket,
        :error,
        "Sent to #{result.sent} riders. Could not send to #{names}. Open their chats to retry individually."
      )
    end
  end

  defp error_text(error) when is_binary(error), do: error
  defp error_text(_), do: "Could not save this bulk message. Please check the name and message."

  defp consume_media(socket) do
    consume_uploaded_entries(socket, :media, fn %{path: path}, %{client_type: content_type} ->
      {:ok, BikeBrigade.MediaStorage.upload_file!(path, content_type)}
    end)
  end

  defp refresh(socket) do
    a = socket.assigns
    tab = if a.params["tab"] in ["campaigns", "groups"], do: a.params["tab"], else: "all"
    mine = a.params["mine"] != "false"
    campaigns = Inbox.campaigns(a.current_user, mine)
    groups = Inbox.groups()

    contexts =
      case tab do
        "campaigns" ->
          Enum.map(campaigns, fn c ->
            %{
              id: c.id,
              name: BikeBrigadeWeb.CampaignHelpers.name(c),
              ids: Enum.map(c.riders, & &1.id),
              detail:
                "#{Calendar.strftime(BikeBrigade.LocalizedDateTime.localize(c.delivery_start), "%b %-d")} · #{c.program.name}",
              group: nil
            }
          end)

        "groups" ->
          Enum.map(groups, fn g ->
            %{
              id: g.id,
              name: g.name,
              ids: Enum.map(g.riders, & &1.id),
              detail:
                "Started by #{g.creator.name} · #{Calendar.strftime(g.inserted_at, "%b %-d")}",
              group: %{
                "body" => g.body,
                "creator" => g.creator.name,
                "created" => Calendar.strftime(g.inserted_at, "%b %-d")
              }
            }
          end)

        _ ->
          []
      end

    context =
      Enum.find(contexts, &(to_string(&1.id) == a.params["context"])) || List.first(contexts)

    conversations =
      if tab == "all",
        do: Messaging.list_sms_conversations(),
        else: Messaging.list_sms_conversations_for_riders(if(context, do: context.ids, else: []))

    conversations =
      Enum.map(conversations, fn {rider, message} ->
        {%{rider | name: rider.name || rider.phone || "Unnamed rider"}, message}
      end)

    search = a.params["search"] || ""

    visible =
      Enum.filter(conversations, fn {r, _} ->
        String.contains?(String.downcase(r.name), String.downcase(search))
      end)

    rider =
      if a.params["rider"],
        do:
          Enum.find_value(conversations, fn {r, _} ->
            if to_string(r.id) == a.params["rider"], do: r
          end),
        else:
          if(tab == "all",
            do:
              case List.first(visible) do
                {r, _} -> r
                _ -> nil
              end
          )

    rider = rider || if(tab == "all", do: rider_from_param(a.params["rider"]))

    rows =
      Enum.map(visible, fn {r, m} ->
        %{
          rider: r,
          latest:
            if(m, do: %{"incoming" => m.from == r.phone, "body" => m.body || preview_message(m)}),
          link: inbox_path(a, %{"rider" => r.id, "context" => context && context.id})
        }
      end)

    first = Date.beginning_of_week(BikeBrigade.LocalizedDateTime.today())

    socket
    |> assign(
      tab: tab,
      mine: mine,
      search: search,
      context: context,
      contexts: contexts,
      rider: rider,
      rows: rows,
      week_label:
        Calendar.strftime(first, "%b %-d") <>
          "–" <> Calendar.strftime(Date.add(first, 6), "%b %-d"),
      tabs: [
        %{value: "all", label: "All conversations", count: nil},
        %{value: "campaigns", label: "Campaigns", count: length(campaigns)},
        %{value: "groups", label: "Bulk messages", count: length(groups)}
      ]
    )
    |> stream(:conversations, visible,
      reset: true,
      dom_id: fn {r, _} -> "conversation-list-item:#{r.id}" end
    )
    |> push_event("conversation_list:select_rider", %{id: rider && rider.id})
  end

  defp inbox_path(assigns, changes) do
    params =
      assigns.params |> Map.merge(changes) |> Enum.reject(fn {_, v} -> is_nil(v) end) |> Map.new()

    ~p"/messages/inbox?#{params}"
  end

  defp rider_from_param(id) when is_binary(id) do
    case Integer.parse(id) do
      {id, ""} when id > 0 -> Riders.get_rider(id)
      _ -> nil
    end
  end

  defp rider_from_param(_), do: nil
end
