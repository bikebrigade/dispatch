defmodule BikeBrigade.SlackApi.PayloadBuilderTest do
  use BikeBrigade.DataCase, async: true

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
end
