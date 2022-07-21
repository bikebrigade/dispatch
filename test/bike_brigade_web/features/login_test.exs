defmodule BikeBrigadeWeb.Features.LoginTest do
  use ExUnit.Case, async: false
  use Wallaby.Feature

  import BikeBrigade.Fixtures
  import Wallaby.Query

  alias BikeBrigade.SmsService.FakeSmsService

  feature "user can visit homepage", %{session: session} do
    user = fixture(:user)

    session
    |> visit("/login")
    |> assert_has(css("h2", text: "Sign into your Bike Brigade account"))
    |> fill_in(text_field("Phone number"), with: user.phone)
    |> click(button("Get Login Code"))
    |> assert_has(
      css("*[role=notice]", text: "We sent an authentication code to your phone number")
    )
    |> fill_in(text_field("Authentication code"), with: get_authentication_code())
    |> click(button("Sign in"))

    assert current_path(session) == "/campaigns"
  end

  def get_authentication_code() do
    message =
      FakeSmsService.last_message()
      |> Keyword.fetch!(:body)

    [_, authentication_code] = Regex.run(~r[Your BikeBrigade access code is (\d+)\.], message)

    authentication_code
  end
end
