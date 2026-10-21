defmodule BikeBrigadeWeb.SmsMessageLive.Inbox do
  use BikeBrigadeWeb, :live_view

  alias BikeBrigade.{Messaging, Riders, Delivery, Presence, LocalizedDateTime}
  alias BikeBrigadeWeb.CampaignHelpers
  alias BikeBrigadeWeb.Components.{ConversationComponent, RiderDeliveriesComponent}

  import BikeBrigadeWeb.Components.SMSMessageListComponent

  import BikeBrigadeWeb.Components.MessagingInbox, only: [merged_inbox: 1, attachments: 1]
  import BikeBrigadeWeb.Components.PresenceComponents, only: [currently_viewing: 1]

  @presence_topic "messaging_presence"

  on_mount {BikeBrigadeWeb.LiveHooks.FeatureFlags, {:require, :unified_messaging, "/messages"}}

  @impl true
  def mount(_params, _session, socket) do
    if connected?(socket) do
      Messaging.subscribe()
      Delivery.subscribe()
      BikeBrigadeWeb.Endpoint.subscribe(@presence_topic)
      Presence.track(self(), @presence_topic, socket.assigns.current_user.id, %{})
    end

    presence = Presence.list(@presence_topic)

    {:ok,
     socket
     |> allow_upload(:media, accept: ~w(.gif .png .jpg .jpeg), max_entries: 10)
     |> assign(
       page: :messages,
       page_title: "Messages",
       wide_content: true,
       presence: presence,
       others_present: others_present(socket.assigns.current_user, presence),
       confirm_send: BikeBrigade.SmsService.sending_confirmation_message(),
       loaded: %{}
     )
     |> reset_bulk_form()
     |> reset_everyone_form()}
  end

  @impl true
  def handle_params(params, _url, socket) do
    # Every inbox param is a plain string; drop anything else (e.g. ?search[]=x).
    params = for {key, value} <- params, is_binary(value), into: %{}, do: {key, value}

    {:noreply,
     socket
     |> assign(params: params, modal: params["compose"] == "new", everyone_open: false)
     |> load()}
  end

  @impl true
  def handle_event("toggle_mine", _params, socket) do
    mine = to_string(!socket.assigns.mine)

    {:noreply,
     push_patch(socket,
       to: inbox_path(socket.assigns, %{"mine" => mine, "context" => nil, "rider" => nil})
     )}
  end

  def handle_event("search", %{"search" => search}, socket) do
    {:noreply,
     push_patch(socket, to: inbox_path(socket.assigns, %{"search" => search}), replace: true)}
  end

  def handle_event("bulk", _params, socket) do
    socket =
      Enum.reduce(socket.assigns.uploads.media.entries, socket, fn entry, socket ->
        cancel_upload(socket, :media, entry.ref)
      end)

    {:noreply, socket |> reset_bulk_form() |> assign(modal: true)}
  end

  # Opened from /messages/new, the drawer is part of the URL; otherwise it's just state.
  def handle_event("close_bulk", _params, socket) do
    if socket.assigns.params["compose"] do
      {:noreply, push_patch(socket, to: inbox_path(socket.assigns, %{"compose" => nil}))}
    else
      {:noreply, assign(socket, modal: false)}
    end
  end

  def handle_event("validate_bulk", %{"bulk_message" => attrs}, socket) do
    changeset =
      attrs
      |> Messaging.change_bulk_message(has_media: has_media?(socket))
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, bulk_form: to_form(changeset))}
  end

  def handle_event("toggle_save_group", _params, socket) do
    form = socket.assigns.bulk_form
    attrs = Map.put(form.params, "save_group", to_string(!save_group?(form)))

    changeset =
      attrs
      |> Messaging.change_bulk_message(has_media: has_media?(socket))
      |> Map.put(:action, form.source.action)

    {:noreply, assign(socket, bulk_form: to_form(changeset))}
  end

  def handle_event("open_everyone", _params, socket) do
    {:noreply, socket |> reset_everyone_form() |> assign(everyone_open: true)}
  end

  def handle_event("close_everyone", _params, socket),
    do: {:noreply, assign(socket, everyone_open: false)}

  def handle_event("validate_everyone", %{"everyone" => attrs}, socket),
    do: {:noreply, assign(socket, everyone_form: to_form(attrs, as: :everyone))}

  def handle_event("cancel_upload", %{"ref" => ref}, socket),
    do: {:noreply, cancel_upload(socket, :media, ref)}

  # On success the slideover closes by patching `compose` out of the URL (handle_params
  # derives `modal` from it), and a saved group is opened.
  def handle_event("send_bulk", %{"bulk_message" => attrs}, socket) do
    case send_with_media(socket, attrs) do
      {:ok, %{group: nil} = result} ->
        {:noreply,
         socket
         |> finish_send(result)
         |> reset_bulk_form()
         |> push_patch(to: inbox_path(socket.assigns, %{"compose" => nil}))}

      {:ok, result} ->
        path =
          inbox_path(socket.assigns, %{
            "tab" => "groups",
            "context" => result.group.id,
            "rider" => nil,
            "compose" => nil
          })

        {:noreply,
         socket
         |> finish_send(result)
         |> reset_bulk_form()
         |> invalidate([:lists])
         |> push_patch(to: path)}

      {:error, :media} ->
        {:noreply, put_flash(socket, :error, media_error(socket))}

      {:error, changeset} ->
        {:noreply, assign(socket, bulk_form: to_form(changeset))}
    end
  end

  def handle_event(
        "message_group",
        %{"everyone" => %{"body" => body}},
        %{assigns: %{context: context}} = socket
      )
      when not is_nil(context) do
    # Always use the complete server-resolved roster, even when search narrows the visible list.
    attrs = %{
      rider_ids: context.ids,
      body: body,
      campaign_id: if(socket.assigns.tab == "campaigns", do: context.id)
    }

    case send_with_media(socket, attrs) do
      {:ok, result} ->
        {:noreply, socket |> finish_send(result) |> assign(everyone_open: false)}

      {:error, :media} ->
        {:noreply, put_flash(socket, :error, media_error(socket))}

      {:error, changeset} ->
        # Body errors show under the field; an empty roster can only be reported here.
        socket = assign(socket, everyone_form: to_form(changeset, as: :everyone))

        case translate_errors(changeset.errors, :rider_ids) do
          [] -> {:noreply, socket}
          errors -> {:noreply, put_flash(socket, :error, Enum.join(errors, " "))}
        end
    end
  end

  # PubSub updates only touch what the event affects; everything else stays as loaded.
  @impl true
  def handle_info({:message_created, message}, socket) do
    {:noreply,
     socket |> update_selected_conversation(message) |> move_conversation_to_top(message)}
  end

  def handle_info({:message_updated, message}, socket) do
    {:noreply, update_selected_conversation(socket, message)}
  end

  def handle_info({event, %Delivery.Task{} = task}, socket)
      when event in [:task_created, :task_updated, :task_deleted] do
    %{context: context, rider: rider, deliveries: deliveries, tab: tab} = socket.assigns

    stale =
      [
        tab == "campaigns" && context && context.id == task.campaign_id && :delivery_counts,
        rider && (task.assigned_rider_id == rider.id || task_shown?(deliveries, task)) &&
          :deliveries
      ]
      |> Enum.filter(& &1)

    {:noreply, reload(socket, stale)}
  end

  def handle_info({event, %Delivery.CampaignRider{} = campaign_rider}, socket)
      when event in [:campaign_rider_created, :campaign_rider_updated, :campaign_rider_deleted] do
    %{tab: tab, contexts: contexts, rider: rider} = socket.assigns

    stale =
      [
        tab == "campaigns" && Enum.any?(contexts, &(&1.id == campaign_rider.campaign_id)) &&
          :lists,
        tab == "campaigns" && socket.assigns.linked_context &&
          socket.assigns.linked_context.id == campaign_rider.campaign_id && :linked_context,
        rider && rider.id == campaign_rider.rider_id && :deliveries
      ]
      |> Enum.filter(& &1)

    {:noreply, reload(socket, stale)}
  end

  def handle_info({:bulk_message_group_created, group}, socket) do
    # Our own sends already reloaded the lists before opening the new group.
    if Enum.any?(socket.assigns.contexts, &(&1.group && &1.id == group.id)),
      do: {:noreply, socket},
      else: {:noreply, reload(socket, [:lists])}
  end

  def handle_info({:campaign_updated, _campaign}, socket) do
    if socket.assigns.tab == "campaigns",
      do: {:noreply, reload(socket, [:lists])},
      else: {:noreply, socket}
  end

  def handle_info(%{event: "presence_diff", payload: %{joins: joins, leaves: leaves}}, socket) do
    presence = socket.assigns.presence |> Map.merge(joins) |> Map.drop(Map.keys(leaves))

    {:noreply,
     assign(socket,
       presence: presence,
       others_present: others_present(socket.assigns.current_user, presence)
     )}
  end

  def handle_info(_message, socket), do: {:noreply, socket}

  defp update_selected_conversation(socket, message) do
    if socket.assigns.rider && socket.assigns.rider.id == message.rider_id do
      send_update(ConversationComponent, id: message.rider_id, conversation: [message])
    end

    socket
  end

  defp move_conversation_to_top(%{assigns: %{tab: "all"}} = socket, message) do
    with %Riders.Rider{} = rider <- Riders.get_rider(message.rider_id),
         rider = with_display_name(rider),
         true <- matches_search?(rider, socket.assigns.search) do
      socket
      |> stream_delete_by_dom_id(:conversations, conversation_dom_id(rider))
      |> stream_insert(:conversations, {rider, message}, at: 0)
    else
      _ -> socket
    end
  end

  defp move_conversation_to_top(%{assigns: %{context: context}} = socket, message)
       when not is_nil(context) do
    case List.keytake(socket.assigns.conversations, message.rider_id, 0) do
      {{_id, rider, _previous}, rest} ->
        socket
        |> assign(conversations: [{rider.id, rider, message} | rest])
        |> assign_rows()

      nil ->
        socket
    end
  end

  defp move_conversation_to_top(socket, _message), do: socket

  defp task_shown?(deliveries, task) do
    Enum.any?(deliveries, fn campaign -> Enum.any?(campaign.tasks, &(&1.id == task.id)) end)
  end

  defp reset_bulk_form(socket) do
    assign(socket, bulk_form: to_form(Messaging.change_bulk_message()))
  end

  defp reset_everyone_form(socket) do
    assign(socket, everyone_form: to_form(%{"body" => ""}, as: :everyone))
  end

  # Attachments with errors (too large, wrong type) are listed but never uploaded, so
  # only count valid ones; see send_with_media/2 for why they also block sending.
  defp has_media?(socket), do: Enum.any?(socket.assigns.uploads.media.entries, & &1.valid?)

  defp media_ready?(%{entries: entries} = upload) do
    upload_errors(upload) == [] and Enum.all?(entries, &(&1.valid? and &1.done?))
  end

  defp media_error(socket) do
    if Enum.all?(socket.assigns.uploads.media.entries, & &1.valid?),
      do: "Photos are still uploading. Try sending again in a moment.",
      else: "Remove the photos that can't be attached, then send again."
  end

  defp save_group?(form), do: Phoenix.HTML.Form.input_value(form, :save_group) in [true, "true"]

  # The rider picker has no field of its own to mark as used, so only show its error
  # once the form has been submitted.
  defp rider_errors(%{source: %{action: :insert} = changeset}),
    do: translate_errors(changeset.errors, :rider_ids)

  defp rider_errors(_form), do: []

  # Validate before consuming uploads so a rejected send keeps the attachments. LiveView
  # can only consume finished, valid uploads, so anything else blocks the send.
  defp send_with_media(socket, attrs) do
    changeset = Messaging.change_bulk_message(attrs, has_media: has_media?(socket))

    cond do
      not media_ready?(socket.assigns.uploads.media) ->
        {:error, :media}

      changeset.valid? ->
        media =
          consume_uploaded_entries(socket, :media, fn %{path: path},
                                                      %{client_type: content_type} ->
            {:ok, BikeBrigade.MediaStorage.upload_file!(path, content_type)}
          end)

        Messaging.send_bulk_message(socket.assigns.current_user, attrs, media)

      true ->
        Ecto.Changeset.apply_action(changeset, :insert)
    end
  end

  # The conversation list updates itself from the :message_created broadcasts.
  defp finish_send(socket, %{failed: [], sent: sent}) do
    put_flash(socket, :info, "Sent to #{sent} riders.")
  end

  defp finish_send(socket, %{failed: failed, sent: sent}) do
    names = Enum.map_join(failed, ", ", &rider_display_name/1)

    put_flash(
      socket,
      :error,
      "Sent to #{sent} riders. Could not send to #{names}. Open their chats to retry individually."
    )
  end

  defp others_present(current_user, presence) do
    for {_, %{user: user}} <- presence, user && user.id != current_user.id, do: user
  end

  # Each piece of the page is loaded from a key derived from the URL params, and only
  # reloaded when that key changes (or when an event invalidates it):
  #
  #   * :lists           - this week's campaigns and the saved groups (tab counts, contexts)
  #   * :conversations   - all conversations ("All" tab, streamed) or the context's roster
  #   * :delivery_counts - per-rider delivery progress for the selected campaign
  #   * :deliveries      - the selected rider's deliveries panel
  defp load(socket) do
    %{params: params} = socket.assigns
    tab = if params["tab"] in ["campaigns", "groups"], do: params["tab"], else: "all"

    socket
    |> assign(tab: tab, mine: params["mine"] != "false", search: params["search"] || "")
    |> load_lists()
    |> load_linked_context()
    |> assign_context()
    |> load_conversations()
    |> assign_rider()
    |> load_delivery_counts()
    |> load_deliveries()
    |> assign_rows()
    |> assign(
      deliveries_link: inbox_path(socket.assigns, %{"panel" => "deliveries"}),
      deliveries_back: inbox_path(socket.assigns, %{"panel" => nil})
    )
    |> push_selected_rider()
  end

  defp push_selected_rider(%{assigns: %{rider: rider}} = socket),
    do: push_event(socket, "conversation_list:select_rider", %{id: rider && rider.id})

  defp invalidate(socket, keys) do
    assign(socket, loaded: Map.drop(socket.assigns.loaded, keys))
  end

  defp reload(socket, []), do: socket
  defp reload(socket, keys), do: socket |> invalidate(keys) |> load()

  defp loaded?(socket, key, value), do: Map.get(socket.assigns.loaded, key, :none) == value

  defp mark_loaded(socket, key, value),
    do: assign(socket, loaded: Map.put(socket.assigns.loaded, key, value))

  defp load_lists(socket) do
    %{tab: tab, mine: mine, current_user: current_user} = socket.assigns
    key = {tab, mine}

    if loaded?(socket, :lists, key) do
      socket
    else
      week_start = Date.beginning_of_week(LocalizedDateTime.today())

      campaigns =
        Delivery.list_campaigns(
          start_date: week_start,
          end_date: Date.add(week_start, 6),
          lead_id: if(mine, do: current_user.id),
          preload: [:program, :riders]
        )
        |> Enum.reverse()

      groups = Messaging.list_bulk_message_groups()

      contexts =
        case tab do
          "campaigns" -> Enum.map(campaigns, &campaign_context/1)
          "groups" -> Enum.map(groups, &group_context/1)
          "all" -> []
        end

      socket
      |> assign(
        contexts: contexts,
        week_label: "#{format_day(week_start)}–#{format_day(Date.add(week_start, 6))}",
        tabs: [
          %{value: "all", label: "All conversations", count: nil},
          %{value: "campaigns", label: "Campaigns", count: length(campaigns)},
          %{value: "groups", label: "Bulk messages", count: length(groups)}
        ]
      )
      |> mark_loaded(:lists, key)
    end
  end

  # The campaign page links here with its campaign as the context, which may not be in
  # this week's list (or may be led by someone else), so it's loaded on its own.
  defp load_linked_context(socket) do
    %{tab: tab, contexts: contexts, params: params} = socket.assigns
    id = params["context"]

    key =
      tab == "campaigns" && id && !Enum.any?(contexts, &(to_string(&1.id) == id)) && id

    if loaded?(socket, :linked_context, key) do
      socket
    else
      linked =
        with id when is_binary(id) <- key,
             {id, ""} <- Integer.parse(id),
             %Delivery.Campaign{} = campaign <-
               Delivery.get_campaign(id, preload: [:program, :riders]) do
          campaign_context(campaign)
        else
          _ -> nil
        end

      socket
      |> assign(linked_context: linked)
      |> mark_loaded(:linked_context, key)
    end
  end

  # Without a context in the URL, the first one is selected. An unknown context selects
  # nothing, so "Message everyone" can never fall back to a different roster.
  defp assign_context(socket) do
    %{contexts: contexts, params: params, linked_context: linked} = socket.assigns

    context =
      case params["context"] do
        nil -> List.first(contexts)
        id -> Enum.find(contexts, &(to_string(&1.id) == id)) || linked
      end

    assign(socket, context: context)
  end

  # The "All" tab can hold every conversation, so it's streamed and filtered by the
  # query; a context's roster is small enough to keep in memory and filter locally.
  defp load_conversations(%{assigns: %{tab: "all", search: search}} = socket) do
    key = {:all, search}

    if loaded?(socket, :conversations, key) do
      socket
    else
      visible =
        Messaging.list_sms_conversations()
        |> Enum.map(fn {rider, message} -> {with_display_name(rider), message} end)
        |> Enum.filter(fn {rider, _} -> matches_search?(rider, search) end)

      socket
      |> assign(
        conversations: [],
        first_conversation_rider:
          case visible do
            [{rider, _} | _] -> rider
            [] -> nil
          end
      )
      |> stream(:conversations, visible,
        reset: true,
        dom_id: fn {rider, _} -> conversation_dom_id(rider) end
      )
      |> mark_loaded(:conversations, key)
    end
  end

  defp load_conversations(%{assigns: %{context: context}} = socket) do
    key = context && {context.id, context.ids}

    if loaded?(socket, :conversations, key) do
      socket
    else
      conversations =
        if context do
          for {rider, message} <- Messaging.list_sms_conversations_for_riders(context.ids),
              do: {rider.id, with_display_name(rider), message}
        else
          []
        end

      socket
      |> assign(conversations: conversations, first_conversation_rider: nil)
      |> mark_loaded(:conversations, key)
    end
  end

  defp assign_rider(socket) do
    %{params: params, tab: tab, conversations: conversations} = socket.assigns
    current = socket.assigns[:rider]

    rider =
      case {params["rider"], tab} do
        {nil, "all"} ->
          socket.assigns.first_conversation_rider

        {nil, _} ->
          nil

        {id, "all"} ->
          # A rider who has never been messaged can still be opened from "All".
          if current && to_string(current.id) == id,
            do: current,
            else: rider_from_param(id)

        {id, _} ->
          Enum.find_value(conversations, fn {_, rider, _} ->
            to_string(rider.id) == id && rider
          end)
      end

    assign(socket, rider: rider)
  end

  defp load_delivery_counts(socket) do
    %{tab: tab, context: context} = socket.assigns
    key = tab == "campaigns" && context && context.id

    if loaded?(socket, :delivery_counts, key) do
      socket
    else
      socket
      |> assign(delivery_counts: if(key, do: Delivery.delivery_progress_by_rider(key), else: %{}))
      |> mark_loaded(:delivery_counts, key)
    end
  end

  defp load_deliveries(socket) do
    %{rider: rider, params: params} = socket.assigns
    key = rider && rider.id

    socket =
      if loaded?(socket, :deliveries, key) do
        socket
      else
        socket
        |> assign(deliveries: if(rider, do: Delivery.latest_campaign_tasks(rider), else: []))
        |> mark_loaded(:deliveries, key)
      end

    # Always shown beside the chat on xl screens; narrower screens open it in place
    # of the chat with ?panel=deliveries.
    assign(socket,
      deliveries_open: socket.assigns.deliveries != [] and params["panel"] == "deliveries"
    )
  end

  defp assign_rows(socket) do
    %{conversations: conversations, search: search, context: context} = socket.assigns
    delivery_counts = socket.assigns.delivery_counts

    rows =
      for {_id, rider, message} <- conversations, matches_search?(rider, search) do
        {total, delivered} = Map.get(delivery_counts, rider.id, {0, 0})

        %{
          rider: rider,
          deliveries: RiderDeliveriesComponent.progress(total, delivered),
          latest:
            message &&
              %{
                incoming: message.from == rider.phone,
                body: message.body || preview_message(message)
              },
          link:
            inbox_path(socket.assigns, %{"rider" => rider.id, "context" => context && context.id})
        }
      end

    assign(socket, rows: rows)
  end

  attr :rider, :any, required: true
  attr :current_user, :any, required: true
  attr :close, :string, required: true
  attr :deliveries, :list, required: true
  attr :deliveries_open, :boolean, required: true
  attr :deliveries_link, :string, required: true
  attr :deliveries_back, :string, required: true

  # The rider's conversation, with their deliveries beside it on xl screens. Narrower
  # screens show a summary bar instead, which opens the deliveries in place of the chat.
  defp rider_pane(assigns) do
    ~H"""
    <div class="flex min-h-0 min-w-0 flex-1 gap-4">
      <div class={[
        "min-h-0 min-w-0 flex-1 flex-col",
        if(@deliveries_open, do: "hidden xl:flex", else: "flex")
      ]}>
        <.live_component
          module={ConversationComponent}
          id={@rider.id}
          rider={@rider}
          current_user={@current_user}
          live_action={:show}
          mobile_visible={true}
          back_patch={@close}
          unified_header={true}
          deliveries={RiderDeliveriesComponent.progress(@deliveries)}
          deliveries_link={@deliveries_link}
        />
      </div>
      <.live_component
        :if={@deliveries != []}
        module={RiderDeliveriesComponent}
        id="rider-deliveries"
        rider={@rider}
        campaigns={@deliveries}
        close={@deliveries_back}
        class={[
          if(@deliveries_open, do: "flex w-full", else: "hidden"),
          "xl:flex xl:w-80 xl:shrink-0"
        ]}
      />
    </div>
    """
  end

  defp campaign_context(campaign) do
    %{
      id: campaign.id,
      name: CampaignHelpers.name(campaign),
      ids: Enum.map(campaign.riders, & &1.id),
      detail:
        "#{format_day(LocalizedDateTime.localize(campaign.delivery_start))} · #{campaign.program.name}",
      group: nil
    }
  end

  defp group_context(group) do
    created = LocalizedDateTime.localize(group.inserted_at)

    %{
      id: group.id,
      name: group.name,
      ids: Enum.map(group.riders, & &1.id),
      detail: "Started by #{group.creator.name} · #{format_day(created)}",
      group: %{
        body: group.body,
        creator: group.creator.name,
        created: format_day(created)
      }
    }
  end

  defp rider_from_param(id) do
    with {id, ""} when id > 0 <- Integer.parse(id),
         %Riders.Rider{} = rider <- Riders.get_rider(id) do
      with_display_name(rider)
    else
      _ -> nil
    end
  end

  defp with_display_name(rider), do: %{rider | name: rider_display_name(rider)}

  defp matches_search?(rider, search),
    do: String.contains?(String.downcase(rider.name), String.downcase(search))

  defp conversation_dom_id(rider), do: "conversation-list-item:#{rider.id}"

  defp format_day(date), do: Calendar.strftime(date, "%b %-d")

  defp inbox_path(assigns, changes) do
    params =
      assigns.params |> Map.merge(changes) |> Enum.reject(fn {_, v} -> is_nil(v) end) |> Map.new()

    ~p"/messages/inbox?#{params}"
  end
end
