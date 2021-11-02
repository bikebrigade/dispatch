defmodule BikeBrigade.SmsService do
  use BikeBrigade.Adapter, :sms_service

  alias BikeBrigade.Messaging.SmsMessage
  alias BikeBrigade.Utils
  alias BikeBrigadeWeb.Router.Helpers, as: Routes
  alias BikeBrigadeWeb.Endpoint
  alias BikeBrigade.Accounts

  @type sid :: String.t()
  @type status :: String.t()
  @type success :: {:ok, %{status: status, sid: sid}}
  @type error :: {:error, String.t()}
  @type callback :: :send_callback | :ignore_callback

  @callback send_sms(list()) :: success | error
  @callback request_valid?(String.t(), map, String.t()) :: boolean

  @spec send_sms(SmsMessage.t()) :: success | error
  @spec send_sms(SmsMessage.t(), list()) :: success | error
  def send_sms(message, opts \\ [])

  def send_sms(%SmsMessage{} = message, opts) do
    message
    |> Map.from_struct()
    |> Map.take([:to, :from, :body])
    |> Keyword.new()
    |> Keyword.put(:mediaUrl, SmsMessage.media_urls(message))
    |> send_sms(opts)
  end

  def send_sms(message, opts) when is_list(message) do
    sms_service = Keyword.get(opts, :sms_service, @sms_service)

    payload =
      case Keyword.get(opts, :send_callback, false) do
        true ->
          message
          |> Keyword.put(:statusCallback, status_callback_url())

        false ->
          message
      end

    # Ensure the adapter returns the correct shape
    block_non_dispatch_messages = Utils.get_env(:sms_service, :block_non_dispatch_messages, false)

    case maybe_send_sms(sms_service, payload, block_non_dispatch_messages) do
      {:ok, %{status: _, sid: _}} = result -> result
      {:error, reason} = result when is_binary(reason) -> result
    end
  end

  defp maybe_send_sms(sms_service, payload, false), do: sms_service.send_sms(payload)

  defp maybe_send_sms(sms_service, payload, true) do
    dispatcher_numbers = Accounts.get_dispatcher_phone_numbers()

    if Keyword.fetch!(payload, :to) in dispatcher_numbers do
      sms_service.send_sms(payload)
    else
      {:error, "Sending real SMS messages to non-dispatchers is not allowed here"}
    end
  end

  def request_valid?(url, params, signature) do
    @sms_service.request_valid?(url, params, signature)
  end

  def sending_confirmation_message() do
    if Utils.prod?() == false &&
         adapter() == BikeBrigade.SmsService.Twilio do
      """
      Sending SMS to real numbers.

      You having SmsService.Twilio adapter enabled outside of production which will send real SMS messages to actual phones.

      Be sure you aren't about to spam somebody.

      Consider switching to SmsService.FakeSmsService for development.
      """
    else
      ""
    end
  end

  defp status_callback_url() do
    case Utils.fetch_env!(:sms_service, :status_callback_url) do
      :local ->
        Routes.twilio_url(Endpoint, :status_callback)

      url when is_binary(url) ->
        url
    end
  end
end
