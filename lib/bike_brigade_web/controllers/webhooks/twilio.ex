defmodule BikeBrigadeWeb.Webhooks.Twilio do
  use BikeBrigadeWeb, :controller

  alias BikeBrigade.Messaging
  alias BikeBrigade.Messaging.GoogleDriveUpload
  alias BikeBrigade.Messaging.Slack.RiderSms
  alias BikeBrigade.Riders
  alias BikeBrigade.SmsService

  plug :validate_request

  def incoming_sms(
        conn,
        %{"From" => from_phone, "To" => to_phone, "Body" => body, "SmsMessageSid" => sid} = msg
      ) do
    num_media = String.to_integer(msg["NumMedia"])

    media =
      if num_media > 0 do
        for i <- 0..(num_media - 1) do
          %{url: msg["MediaUrl#{i}"], content_type: msg["MediaContentType#{i}"]}
        end
      else
        []
      end

    rider = Riders.get_rider_by_phone(from_phone)

    {:ok, msg} =
      Messaging.create_sms_message(%{
        from: from_phone,
        to: to_phone,
        incoming: true,
        rider_id: rider && rider.id,
        body: body,
        twilio_sid: sid,
        media: media,
        sent_at: DateTime.utc_now()
      })

    # Save our rider in the struct
    msg = %{msg | rider: rider}

    if rider do
      Task.start(RiderSms, :post_message!, [msg])
      Task.start(GoogleDriveUpload, :upload_media, [msg])
    end

    # todo tell twilio things bad
    send_resp(conn, :ok, "")
  end

  def status_callback(
        conn,
        %{"SmsSid" => sid, "SmsStatus" => status}
      ) do
    if msg = Messaging.get_sms_message_by_twilio_sid(sid) do
      Messaging.update_sms_message(msg, %{twilio_status: status})
    end

    send_resp(conn, :ok, "")
  end

  defp validate_request(conn, _options) do
    signature =
      get_req_header(conn, "x-twilio-signature")
      |> List.first("")

    if SmsService.request_valid?(request_url(conn), conn.params, signature) do
      conn
    else
      conn
      |> put_status(:unauthorized)
      |> json(%{error: "unauthorized"})
      |> halt()
    end
  end
end
