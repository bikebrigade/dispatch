defmodule BikeBrigade.SmsServiceTest do
  use BikeBrigade.DataCase, async: true

  alias BikeBrigade.SmsService
  alias BikeBrigade.SmsService.FakeSmsService
  alias BikeBrigadeWeb.Router.Helpers, as: Routes
  alias BikeBrigadeWeb.Endpoint

  test "It sends an sms with the configured adapter" do
    sms = fixture(:sms_message)

    {:ok, _} = SmsService.send_sms(sms)
    message = FakeSmsService.last_message()
    assert message |> Keyword.fetch!(:body) == sms.body
    assert message |> Keyword.fetch!(:from) == sms.from
    assert message |> Keyword.fetch!(:to) == sms.to
    assert message |> Keyword.fetch!(:mediaUrl) == []
  end

  test "It includes a callback url when asked for" do
    sms = fixture(:sms_message)

    {:ok, _} = SmsService.send_sms(sms, send_callback: true)

    message = FakeSmsService.last_message()

    assert message |> Keyword.fetch!(:body) == sms.body
    assert message |> Keyword.fetch!(:from) == sms.from
    assert message |> Keyword.fetch!(:to) == sms.to
    assert message |> Keyword.fetch!(:mediaUrl) == []

    callback_url = Routes.twilio_url(Endpoint, :status_callback)
    assert message |> Keyword.fetch!(:statusCallback) == callback_url
  end

  test "It includes any media items" do
    media1 = fixture(:sms_media_item, %{url: "http://example.com/one"})
    media2 = fixture(:sms_media_item, %{url: "http://example.com/two"})
    sms = fixture(:sms_message, %{media: [media1, media2]})

    {:ok, _result} = SmsService.send_sms(sms, send_callback: true)
    message = FakeSmsService.last_message()

    assert message |> Keyword.fetch!(:mediaUrl) == [
             "http://example.com/one",
             "http://example.com/two"
           ]
  end

  test "sending a successful message returns status and sid" do
    {:ok, %{status: status, sid: sid}} = SmsService.send_sms(fixture(:sms_message))

    assert status == "queued"
    assert sid |> String.starts_with?("BB")
    assert sid |> String.length() == 34
  end

  test "It can validate a request" do
    assert SmsService.request_valid?("http://example.com", %{}, "signature")
  end

  # TODO: this should probably be a mock... time for Mox?
  defmodule FailSmsService do
    alias BikeBrigade.SmsService

    @behaviour SmsService

    @impl SmsService
    def send_sms(_message) do
      {:error, "timeout"}
    end

    @impl SmsService
    def request_valid?(_url, _params, _signature) do
      true
    end
  end

  test "failure to send a message returns an error tuple" do
    {:error, message} =
      SmsService.send_sms(fixture(:sms_message),
        sms_service: FailSmsService
      )

    assert message == "timeout"
  end
end
