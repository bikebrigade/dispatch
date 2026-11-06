defmodule BikeBrigadeWeb.DeliverySelfieLiveTest do
  use BikeBrigadeWeb.ConnCase
  import Phoenix.LiveViewTest

  alias BikeBrigade.{Delivery, LocalizedDateTime, Selfies}

  setup [:create_campaign, :login_as_rider]

  setup %{conn: conn, campaign: campaign, rider: rider} do
    {:ok, campaign_rider} =
      Delivery.create_campaign_rider(%{campaign_id: campaign.id, rider_id: rider.id})

    {:ok, view, _html} = live(conn, ~p"/app/delivery/#{campaign_rider.token}")
    %{view: view}
  end

  test "uploads a camera photo to the existing selfie folder with delivery context", ctx do
    test_pid = self()

    Req.Test.stub(BikeBrigade.Google, fn conn ->
      {:ok, body, conn} = Plug.Conn.read_body(conn)
      send(test_pid, {:drive_upload, conn, body})
      Req.Test.json(conn, %{"id" => "selfie-id"})
    end)

    assert has_element?(ctx.view, "input[type=file][capture=user]")
    assert has_element?(ctx.view, "#selfie-form button[type=submit][disabled]")
    upload_photo(ctx.view)
    ctx.view |> form("#selfie-form") |> render_submit()

    assert render(ctx.view) =~ "Selfie uploaded. Thank you!"
    refute has_element?(ctx.view, "[data-phx-upload-ref] img")
    assert_receive {:drive_upload, conn, body}
    assert conn.request_path == "/upload/drive/v3/files"
    assert body =~ Selfies.folder()
    date = LocalizedDateTime.to_date(ctx.campaign.delivery_start)
    assert body =~ "#{date} - #{ctx.rider.name} - #{ctx.program.name}"
    assert body =~ "selfie bytes"
    assert has_element?(ctx.view, "#selfie-form button[type=submit][disabled]")
  end

  test "retains the photo for retry when Drive fails", %{view: view} do
    Req.Test.stub(BikeBrigade.Google, fn conn -> Plug.Conn.send_resp(conn, 403, "forbidden") end)
    upload_photo(view)
    view |> form("#selfie-form") |> render_submit()

    assert has_element?(
             view,
             "#selfie-form [role=alert]",
             "Couldn't upload your selfie. Please try again."
           )

    assert has_element?(view, "#selfie-form button[type=submit]:not([disabled])")

    Req.Test.stub(BikeBrigade.Google, fn conn -> Req.Test.json(conn, %{"id" => "retry-id"}) end)
    view |> form("#selfie-form") |> render_submit()
    assert render(view) =~ "Selfie uploaded. Thank you!"
  end

  test "can remove a selected photo", %{view: view} do
    upload_photo(view)
    view |> element("button", "Remove photo") |> render_click()
    assert has_element?(view, "#selfie-form button[type=submit][disabled]")
    refute render(view) =~ "selfie.jpg"
  end

  test "rejects unsupported files", %{view: view} do
    upload =
      file_input(view, "#selfie-form", :selfie, [
        %{name: "file.txt", content: "text", type: "text/plain"}
      ])

    assert {:error, [[_ref, :not_accepted]]} = render_upload(upload, "file.txt")
    assert render(view) =~ "Choose a JPEG, PNG, WebP, or HEIC photo."
  end

  test "rejects oversized photos", %{view: view} do
    upload =
      file_input(view, "#selfie-form", :selfie, [
        %{name: "huge.jpg", content: :binary.copy("a", 20_000_001), type: "image/jpeg"}
      ])

    assert {:error, [[_ref, :too_large]]} = render_upload(upload, "huge.jpg")
    assert render(view) =~ "Photo must be smaller than 20 MB."
  end

  defp upload_photo(view) do
    view
    |> file_input("#selfie-form", :selfie, [
      %{name: "selfie.jpg", content: "selfie bytes", type: "image/jpeg"}
    ])
    |> render_upload("selfie.jpg")
  end
end
