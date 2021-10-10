defmodule BikeBrigade.Messaging.SlackWebhookTest do
  use BikeBrigade.DataCase, async: true

  alias BikeBrigade.Messaging.SlackWebhook
  alias BikeBrigade.SlackApi.FakeSlack
  alias BikeBrigadeWeb.Router.Helpers, as: Routes
  alias BikeBrigadeWeb.Endpoint

  test "The reply button links to the message" do
    rider = fixture(:rider)
    sms = create_sms(%{rider_id: rider.id})

    assert :ok == SlackWebhook.post_message(sms)

    call = FakeSlack.get_last_call()
    %{"blocks" => [%{"accessory" => reply_button}]} = body(call)
    assert reply_button["type"] == "button"
    assert reply_button["url"] == Routes.sms_message_index_url(Endpoint, :show, rider)
    assert reply_button["text"]["text"] == "Reply"
  end

  test "Markdown text is escaped" do
    rider = fixture(:rider, %{name: "Alice Example"})

    sms =
      create_sms(%{
        body: "three is < five & five is > three",
        rider_id: rider.id
      })

    assert :ok == SlackWebhook.post_message(sms)

    body = FakeSlack.get_last_call() |> body()
    block = body["blocks"] |> List.first()

    assert block["text"]["text"] == "*Alice Example*: three is &lt; five &amp; five is &gt; three"
  end

  test "Images are included" do
    image1 = fixture(:sms_media_item)
    image2 = fixture(:sms_media_item)
    sms = create_sms(%{media: [image1, image2]})

    assert :ok == SlackWebhook.post_message(sms)

    [first, second] =
      FakeSlack.get_last_call()
      |> body()
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

  def body(call) do
    Jason.decode!(call.body)
  end
end
