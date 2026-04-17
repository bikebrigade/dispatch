defmodule BikeBrigade.SlackApi.PayloadBuilderTest do
  use BikeBrigade.DataCase, async: true

  alias BikeBrigade.Delivery
  alias BikeBrigade.Delivery.CampaignDeliverySummary
  alias BikeBrigade.SlackApi.PayloadBuilder

  use Phoenix.VerifiedRoutes, endpoint: BikeBrigadeWeb.Endpoint, router: BikeBrigadeWeb.Router

  describe "When an SMS message from a rider is provided" do
    test "The payload is formatted with a reply button linking to the message" do
      channel_id = "123"
      rider = fixture(:rider)
      message = create_sms(%{rider_id: rider.id})

      payload = PayloadBuilder.build(channel_id, message)

      %{"blocks" => [%{"accessory" => reply_button}]} = Jason.decode!(payload)
      assert reply_button["type"] == "button"
      assert reply_button["url"] == url(~p"/messages/#{rider}")
      assert reply_button["text"]["text"] == "Reply"
    end
  end

  describe "When a string is provided" do
    test "The payload is formatted correctly" do
      channel_id = "123"
      message = "hi!"
      payload = PayloadBuilder.build(channel_id, message)

      %{
        "blocks" => [%{"text" => %{"text" => "hi!", "type" => "mrkdwn"}, "type" => "section"}],
        "channel" => "123"
      } = Jason.decode!(payload)
    end
  end

  test "Markdown text is escaped" do
    channel_id = "123"
    rider = fixture(:rider, %{name: "Alice Example"})

    message =
      create_sms(%{
        body: "three is < five & five is > three",
        rider_id: rider.id
      })

    payload = PayloadBuilder.build(channel_id, message)

    body = Jason.decode!(payload)
    block = body["blocks"] |> List.first()

    import Phoenix.VerifiedRoutes

    url = url(~p"/riders/#{rider.id}")

    assert block["text"]["text"] ==
             "<#{url}|*Alice Example*>: three is &lt; five &amp; five is &gt; three"
  end

  test "Images are included" do
    channel_id = "123"
    image1 = fixture(:sms_media_item)
    image2 = fixture(:sms_media_item)
    message = create_sms(%{media: [image1, image2]})

    payload = PayloadBuilder.build(channel_id, message)

    [first, second] =
      payload
      |> Jason.decode!()
      |> Map.get("blocks")
      |> Enum.filter(fn block -> block["type"] == "image" end)

    assert first["image_url"] == image1.url
    assert second["image_url"] == image2.url

    assert first["alt_text"] == "Rider sent us media"
    assert second["alt_text"] == "Rider sent us media"
  end

  defp create_sms(attrs, rider \\ fixture(:rider)) do
    defaults = %{rider_id: rider.id}
    fixture(:sms_message, Map.merge(defaults, attrs))
  end

  describe "build_delivery_summary" do
    setup do
      campaign = fixture(:campaign)
      %{campaign: campaign}
    end

    test "header block contains program name and campaign URL", %{campaign: campaign} do
      payload = build_delivery_summary_payload(campaign)
      %{"blocks" => [%{"text" => %{"text" => header_text}} | _]} = Jason.decode!(payload)

      assert header_text =~ campaign.program.name
      assert header_text =~ url(~p"/campaigns/#{campaign.id}")
    end

    test "summary block shows total and completed delivery counts", %{campaign: campaign} do
      rider = fixture(:rider)
      fixture(:task, %{campaign: campaign, rider: rider, delivery_status: :completed})
      fixture(:task, %{campaign: campaign, rider: rider})

      payload = build_delivery_summary_payload(campaign)
      %{"blocks" => [_, %{"text" => %{"text" => summary_text}} | _]} = Jason.decode!(payload)

      assert summary_text =~ "Deliveries: 2"
      assert summary_text =~ "Completed: 1"
    end

    test "unassigned tasks appear in a separate block", %{campaign: campaign} do
      fixture(:task, %{campaign: campaign})

      payload = build_delivery_summary_payload(campaign)
      %{"blocks" => blocks} = Jason.decode!(payload)

      unassigned =
        Enum.find(blocks, fn b ->
          b["type"] == "section" and String.contains?(b["text"]["text"], "Unassigned Deliveries")
        end)

      assert unassigned != nil
    end

    test "no unassigned block when all tasks have assigned riders", %{campaign: campaign} do
      rider = fixture(:rider)
      fixture(:task, %{campaign: campaign, rider: rider})

      payload = build_delivery_summary_payload(campaign)
      %{"blocks" => blocks} = Jason.decode!(payload)

      refute Enum.any?(blocks, fn b ->
               b["type"] == "section" and
                 String.contains?(b["text"]["text"], "Unassigned Deliveries")
             end)
    end

    test "rider blocks are sorted alphabetically by name", %{campaign: campaign} do
      r1 = fixture(:rider, %{name: "Zara"})
      r2 = fixture(:rider, %{name: "Alice"})
      fixture(:task, %{campaign: campaign, rider: r1})
      fixture(:task, %{campaign: campaign, rider: r2})

      payload = build_delivery_summary_payload(campaign)
      %{"blocks" => blocks} = Jason.decode!(payload)

      rider_texts =
        blocks
        |> Enum.filter(fn b ->
          b["type"] == "section" and String.contains?(b["text"]["text"], ":bicyclist:")
        end)
        |> Enum.map(& &1["text"]["text"])

      assert [first | _] = rider_texts
      assert first =~ "Alice"
      assert List.last(rider_texts) =~ "Zara"
    end

    test "rider block shows completed/total task count", %{campaign: campaign} do
      rider = fixture(:rider)
      fixture(:task, %{campaign: campaign, rider: rider, delivery_status: :completed})
      fixture(:task, %{campaign: campaign, rider: rider})

      payload = build_delivery_summary_payload(campaign)
      %{"blocks" => blocks} = Jason.decode!(payload)

      rider_block =
        Enum.find(blocks, fn b ->
          b["type"] == "section" and String.contains?(b["text"]["text"], ":bicyclist:")
        end)

      assert rider_block["text"]["text"] =~ "(1/2)"
    end

    test "same-day campaign shows full date with time range" do
      campaign =
        fixture(:campaign, %{
          delivery_start: ~U[2026-03-16 14:00:00Z],
          delivery_end: ~U[2026-03-16 18:00:00Z]
        })

      payload = build_delivery_summary_payload(campaign)
      %{"blocks" => [_, %{"text" => %{"text" => summary_text}} | _]} = Jason.decode!(payload)

      # UTC 14:00 = 10:00 AM EDT, UTC 18:00 = 2:00 PM EDT (America/Toronto)
      assert summary_text =~ "Monday March 16, 2026"
      assert summary_text =~ "10:00 AM - 2:00 PM"
    end

    test "multi-day campaign shows short datetime range" do
      campaign =
        fixture(:campaign, %{
          delivery_start: ~U[2026-03-16 14:00:00Z],
          delivery_end: ~U[2026-03-17 18:00:00Z]
        })

      payload = build_delivery_summary_payload(campaign)
      %{"blocks" => [_, %{"text" => %{"text" => summary_text}} | _]} = Jason.decode!(payload)

      assert summary_text =~ "Mon Mar 16"
      assert summary_text =~ "Tue Mar 17"
    end

    test "special characters in names are mrkdwn-escaped", %{campaign: campaign} do
      rider = fixture(:rider, %{name: "Alice & Bob"})
      fixture(:task, %{campaign: campaign, rider: rider, dropoff_name: "Name <With> Specials"})

      payload = build_delivery_summary_payload(campaign)

      assert payload =~ "Alice &amp; Bob"
      assert payload =~ "Name &lt;With&gt; Specials"
    end

    test "shows condensed summary when total tasks exceed threshold", %{campaign: campaign} do
      rider = fixture(:rider)

      # Create 16 tasks (above the threshold of 15)
      for _ <- 1..16 do
        fixture(:task, %{campaign: campaign, rider: rider})
      end

      payload = build_delivery_summary_payload(campaign)
      %{"blocks" => blocks} = Jason.decode!(payload)

      # Should have only 1 block with condensed summary
      assert length(blocks) == 1

      [%{"text" => %{"text" => text}}] = blocks
      assert text =~ campaign.program.name
      assert text =~ url(~p"/campaigns/#{campaign.id}")
      assert text =~ "Deliveries: 16"
      assert text =~ "Completed: 0"

      # Should NOT contain rider details
      refute text =~ ":bicyclist:"
    end

    test "shows detailed summary when total tasks at or below threshold", %{campaign: campaign} do
      rider = fixture(:rider)

      # Create exactly 15 tasks (at the threshold)
      for _ <- 1..15 do
        fixture(:task, %{campaign: campaign, rider: rider})
      end

      payload = build_delivery_summary_payload(campaign)
      %{"blocks" => blocks} = Jason.decode!(payload)

      # Should have multiple blocks (header, summary, divider, rider block)
      assert length(blocks) > 1

      # Should contain rider details
      rider_block =
        Enum.find(blocks, fn b ->
          b["type"] == "section" and String.contains?(b["text"]["text"], ":bicyclist:")
        end)

      assert rider_block != nil
    end
  end

  defp build_delivery_summary_payload(campaign, channel_id \\ "C123") do
    {_riders, tasks} = Delivery.campaign_riders_and_tasks(campaign)
    cds = Enum.into(tasks, CampaignDeliverySummary.new(campaign))
    PayloadBuilder.build_delivery_summary(channel_id, cds)
  end
end
