defmodule BikeBrigade.SlackApi.PayloadBuilder do
  alias BikeBrigade.Messaging.SmsMessage
  alias BikeBrigade.Delivery.Campaign
  alias BikeBrigade.LocalizedDateTime
  use Phoenix.VerifiedRoutes, endpoint: BikeBrigadeWeb.Endpoint, router: BikeBrigadeWeb.Router

  @full_date_format "%A %B %-d, %Y"
  @time_format "%-I:%M %p"
  @short_date_time_format "%a %b %-d, %-I:%M %p"

  def build(channel_id, %SmsMessage{rider: rider} = message) do
    text =
      "<#{url(~p"/riders/#{rider}")}|*#{rider.name}*>: #{filter_mrkdwn(message.body)}"

    %{
      channel: channel_id,
      blocks: [
        %{
          type: "section",
          text: %{
            type: "mrkdwn",
            text: text
          },
          accessory: %{
            type: "button",
            text: %{
              type: "plain_text",
              text: "Reply",
              emoji: true
            },
            url: url(~p"/messages/#{rider}")
          }
        }
        | for m <- message.media do
            %{
              type: "image",
              image_url: m.url,
              alt_text: "Rider sent us media"
            }
          end
      ]
    }
    |> Jason.encode!()
  end

  def build(channel_id, message) do
    %{
      channel: channel_id,
      blocks: [
        %{
          type: "section",
          text: %{
            type: "mrkdwn",
            text: message
          }
        }
      ]
    }
    |> Jason.encode!()
  end

  def build_delivery_summary(channel_id, %Campaign{} = campaign, {riders, tasks}) do
    date_line = format_campaign_date_range(campaign)

    total = length(tasks)
    completed = Enum.count(tasks, &(&1.delivery_status == :completed))

    header = ":bar_chart: #{campaign.program.name} Summary #{url(~p"/campaigns/#{campaign}")}"
    summary = "#{date_line}\n\nDeliveries: #{total}\nCompleted: #{completed}"

    rider_sections = build_rider_sections(riders)

    # Find tasks that aren't assigned to any rider in the riders list
    assigned_task_ids =
      riders
      |> Enum.flat_map(& &1.assigned_tasks)
      |> MapSet.new(& &1.id)

    unassigned_tasks =
      tasks
      |> Enum.reject(&MapSet.member?(assigned_task_ids, &1.id))

    unassigned_sections = build_unassigned_sections(unassigned_tasks)

    blocks =
      [
        %{type: "section", text: %{type: "mrkdwn", text: header}},
        %{type: "section", text: %{type: "mrkdwn", text: summary}},
        %{type: "divider"}
      ] ++ rider_sections ++ unassigned_sections

    %{channel: channel_id, blocks: blocks}
    |> Jason.encode!()
  end

  defp build_rider_sections(riders) do
    riders
    |> Enum.filter(fn rider -> rider.assigned_tasks != [] end)
    |> Enum.flat_map(fn rider ->
      total_tasks = length(rider.assigned_tasks)
      completed_tasks = Enum.count(rider.assigned_tasks, &(&1.delivery_status == :completed))

      status_text = "(#{completed_tasks}/#{total_tasks})"

      task_lines =
        rider.assigned_tasks
        |> Enum.map_join("\n", fn task ->
          items_text = format_task_items(task)
          status_icon = delivery_status_icon(task.delivery_status)
          "#{filter_mrkdwn(task.dropoff_name)} - #{items_text} #{status_icon}"
        end)

      [
        %{
          type: "section",
          text: %{
            type: "mrkdwn",
            text: ":biking_woman: *#{filter_mrkdwn(rider.name)}* #{status_text}\n#{task_lines}"
          }
        }
      ]
    end)
  end

  defp build_unassigned_sections([]), do: []

  defp build_unassigned_sections(tasks) do
    task_lines =
      tasks
      |> Enum.map_join("\n", fn task ->
        items_text = format_task_items(task)
        status_icon = delivery_status_icon(task.delivery_status)
        "#{filter_mrkdwn(task.dropoff_name)} - #{items_text} #{status_icon}"
      end)

    [
      %{type: "divider"},
      %{
        type: "section",
        text: %{type: "mrkdwn", text: ":package: *Unassigned Deliveries*\n#{task_lines}"}
      }
    ]
  end

  defp format_task_items(task) do
    task.task_items
    |> Enum.map_join(", ", fn ti -> "#{ti.count} #{ti.item.name}" end)
    |> filter_mrkdwn()
  end

  defp delivery_status_icon(status) do
    case status do
      :completed -> ":white_check_mark:"
      _ -> ":x:"
    end
  end

  defp format_campaign_date_range(%Campaign{delivery_start: start, delivery_end: end_dt}) do
    dates = {LocalizedDateTime.to_date(start), LocalizedDateTime.to_date(end_dt)}

    case dates do
      {date, date} ->
        format_same_day_campaign(start, end_dt)

      {_start_date, _end_date} ->
        format_multi_day_campaign(start, end_dt)
    end
  end

  defp format_same_day_campaign(start, end_dt) do
    date = format_localized(start, @full_date_format)
    start_time = format_localized(start, @time_format)
    end_time = format_localized(end_dt, @time_format)

    "#{date} #{start_time} - #{end_time}"
  end

  defp format_multi_day_campaign(start, end_dt) do
    start_datetime = format_localized(start, @short_date_time_format)
    end_datetime = format_localized(end_dt, @short_date_time_format)

    "#{start_datetime} - #{end_datetime}"
  end

  defp format_localized(datetime, format) do
    datetime
    |> LocalizedDateTime.localize()
    |> Calendar.strftime(format)
  end

  def filter_mrkdwn(nil), do: ""

  def filter_mrkdwn(str) do
    str
    |> String.replace("&", "&amp;")
    |> String.replace("<", "&lt;")
    |> String.replace(">", "&gt;")
  end
end
