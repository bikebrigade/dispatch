defmodule BikeBrigade.SlackApi.PayloadBuilder do
  alias BikeBrigade.Messaging.SmsMessage
  alias BikeBrigade.LocalizedDateTime

  use Phoenix.VerifiedRoutes, endpoint: BikeBrigadeWeb.Endpoint, router: BikeBrigadeWeb.Router

  @full_date_format "%A %B %-d, %Y"
  @time_format "%-I:%M %p"
  @short_date_time_format "%a %b %-d, %-I:%M %p"
  @task_detail_threshold 15

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

  @doc """
  Builds a Slack message payload for a campaign delivery summary.

  When total tasks exceed the threshold, returns a condensed summary with just
  the campaign link and stats. Otherwise, returns a detailed summary with
  per-rider task breakdowns.

  Returns a JSON-encoded string ready to post to the Slack API.
  """
  def build_delivery_summary(channel_id, cds) do
    if cds.total > @task_detail_threshold do
      build_condensed_summary(channel_id, cds)
    else
      build_detailed_summary(channel_id, cds)
    end
  end

  defp build_condensed_summary(channel_id, cds) do
    date_line = format_campaign_date_range(cds)
    campaign_url = url(~p"/campaigns/#{cds.campaign_id}")

    text =
      ":bar_chart: #{filter_mrkdwn(cds.name)} Summary\n#{campaign_url}\n\n#{date_line}\n\nDeliveries: #{cds.total}\nCompleted: #{cds.completed}"

    blocks = [
      %{type: "section", text: %{type: "mrkdwn", text: text}}
    ]

    %{channel: channel_id, blocks: blocks}
    |> Jason.encode!()
  end

  defp build_detailed_summary(channel_id, cds) do
    date_line = format_campaign_date_range(cds)

    header =
      ":bar_chart: #{filter_mrkdwn(cds.name)} Summary #{url(~p"/campaigns/#{cds.campaign_id}")}"

    summary =
      "#{date_line}\n\nDeliveries: #{cds.total}\nCompleted: #{cds.completed}"

    rider_blocks =
      cds.assigned
      |> Map.to_list()
      |> Enum.sort_by(fn {name, _tasks} -> name end)
      |> Enum.map(&build_rider_block/1)

    blocks =
      [
        %{type: "section", text: %{type: "mrkdwn", text: header}},
        %{type: "section", text: %{type: "mrkdwn", text: summary}},
        %{type: "divider"}
      ] ++ rider_blocks

    %{channel: channel_id, blocks: blocks}
    |> Jason.encode!()
  end

  defp format_campaign_date_range(%{delivery_start: start, delivery_end: end_dt}) do
    same_day? = LocalizedDateTime.to_date(start) == LocalizedDateTime.to_date(end_dt)

    if same_day? do
      date = format_localized(start, @full_date_format)
      start_time = format_localized(start, @time_format)
      end_time = format_localized(end_dt, @time_format)
      "#{date} #{start_time} - #{end_time}"
    else
      start_str = format_localized(start, @short_date_time_format)
      end_str = format_localized(end_dt, @short_date_time_format)
      "#{start_str} - #{end_str}"
    end
  end

  defp format_localized(datetime, format) do
    datetime
    |> LocalizedDateTime.localize()
    |> Calendar.strftime(format)
  end

  defp build_rider_block({rider_name, tasks}) do
    task_lines = format_task_lines(tasks)

    %{
      type: "section",
      text: %{
        type: "mrkdwn",
        text: ":bicyclist: *#{filter_mrkdwn(rider_name)}* \n#{task_lines}"
      }
    }
  end

  defp format_task_lines(tasks) do
    tasks
    |> Enum.reverse()
    |> Enum.map_join("\n", &format_task_line/1)
  end

  defp format_task_line(task_data) do
    status_icon = delivery_status_icon(task_data.delivery_status)
    "#{filter_mrkdwn(task_data.dropoff_name)} - #{filter_mrkdwn(task_data.items)} #{status_icon}"
  end

  defp delivery_status_icon(:completed), do: ":white_check_mark:"
  defp delivery_status_icon(_), do: ":bicyclist:"

  def filter_mrkdwn(nil) do
    ""
  end

  def filter_mrkdwn(str) do
    str
    |> String.replace("&", "&amp;")
    |> String.replace("<", "&lt;")
    |> String.replace(">", "&gt;")
  end
end
