defmodule BikeBrigade.SmsService.Twilio do
  alias BikeBrigade.SmsService
  alias BikeBrigade.Utils

  @behaviour SmsService

  @impl SmsService
  def send_sms(message) when is_list(message) do
    case ExTwilio.Message.create(message) do
      {:ok, %{status: status, sid: sid}} ->
        {:ok, %{status: status, sid: sid}}

      {:error, %{"message" => message}, _code} ->
        {:error, message}
    end
  end

  @impl SmsService
  def request_valid?(url, params, signature) do
    url
    |> rewrite_url_scheme()
    |> ExTwilio.RequestValidator.valid?(params, signature)
  end

  defp rewrite_url_scheme(url) do
    # When tunneling https with a proxy like ngrok, it's possible that
    # the request comes to grok at https, TLS is terminated there, and passed
    # on to the Elixir server at http. Since the url that Twilio sent the request
    # to is part of the signature, the request won't validate.
    #
    # We can't blindly rewrite the url to https as it's also possible to configure
    # the webhook to deliver to http://... so we have to check here
    if Utils.dev?() do
      callback = URI.parse(System.get_env("TWILIO_STATUS_CALLBACK"))
      Utils.change_scheme(url, callback.scheme)
    else
      # don't mess with anything other than dev
      url
    end
  end
end
