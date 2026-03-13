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

    # Transform data in single pass
    summary_data = prepare_summary_data(tasks, riders)

    # Build blocks from structured data
    header = ":bar_chart: #{campaign.program.name} Summary #{url(~p"/campaigns/#{campaign}")}"

    summary =
      "#{date_line}\n\nDeliveries: #{summary_data.total}\nCompleted: #{summary_data.completed}"

    rider_blocks =
      summary_data.riders
      |> Map.to_list()
      |> Enum.sort_by(fn {name, _tasks} -> name end)
      |> Enum.map(&build_rider_block/1)

    unassigned_blocks = build_unassigned_block(summary_data.unassigned)

    blocks =
      [
        %{type: "section", text: %{type: "mrkdwn", text: header}},
        %{type: "section", text: %{type: "mrkdwn", text: summary}},
        %{type: "divider"}
      ] ++ rider_blocks ++ unassigned_blocks

    %{channel: channel_id, blocks: blocks}
    |> Jason.encode!()
  end

  defp format_task_items(task) do
    task.task_items
    |> Enum.map_join(", ", fn ti -> ti.item.name end)
    |> filter_mrkdwn()
  end

  defp delivery_status_icon(status) do
    case status do
      :completed -> ":white_check_mark:"
      _ -> ":x:"
    end
  end

  defp prepare_summary_data(tasks, riders) do
    # Build rider ID to name mapping
    rider_names = Map.new(riders, fn rider -> {rider.id, rider.name} end)

    # Reduce tasks to gather statistics
    data =
      Enum.reduce(tasks, %{total: 0, completed: 0, riders: %{}, unassigned: []}, fn task, acc ->
        acc = %{
          acc
          | total: acc.total + 1,
            completed: acc.completed + if(task.delivery_status == :completed, do: 1, else: 0)
        }

        task_data = %{
          dropoff_name: task.dropoff_name,
          task_items: format_task_items(task),
          delivery_status: task.delivery_status
        }

        case task.assigned_rider do
          nil ->
            %{acc | unassigned: [task_data | acc.unassigned]}

          rider ->
            rider_tasks = Map.get(acc.riders, rider.id, [])
            %{acc | riders: Map.put(acc.riders, rider.id, [task_data | rider_tasks])}
        end
      end)

    # Replace rider IDs with names
    riders_with_names =
      Map.new(data.riders, fn {rider_id, tasks} ->
        {Map.get(rider_names, rider_id, "Unknown"), tasks}
      end)

    %{data | riders: riders_with_names}
  end

  defp format_task_line(task_data) do
    status_icon = delivery_status_icon(task_data.delivery_status)
    "#{filter_mrkdwn(task_data.dropoff_name)} - #{task_data.task_items} #{status_icon}"
  end

  defp build_rider_block({rider_name, tasks}) do
    total = length(tasks)
    completed = Enum.count(tasks, &(&1.delivery_status == :completed))
    status_text = "(#{completed}/#{total})"

    task_lines =
      tasks
      |> Enum.reverse()
      |> Enum.map_join("\n", &format_task_line/1)

    %{
      type: "section",
      text: %{
        type: "mrkdwn",
        text: ":bicyclist: *#{filter_mrkdwn(rider_name)}* #{status_text}\n#{task_lines}"
      }
    }
  end

  defp build_unassigned_block([]), do: []

  defp build_unassigned_block(unassigned_tasks) do
    task_lines =
      unassigned_tasks
      |> Enum.reverse()
      |> Enum.map_join("\n", &format_task_line/1)

    [
      %{type: "divider"},
      %{
        type: "section",
        text: %{type: "mrkdwn", text: ":package: *Unassigned Deliveries*\n#{task_lines}"}
      }
    ]
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
