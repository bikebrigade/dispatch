defmodule BikeBrigadeWeb.Features.LoginTest do
  use BikeBrigadeWeb.FeatureCase

  alias BikeBrigade.FeatureTestPages.LoginPage

  test "user can visit homepage", %{session: session} do
    user = fixture(:user)

    session
    |> LoginPage.visit()
    |> assert_has(LoginPage.sign_in_prompt())
    |> LoginPage.fill_in_phone_number(user.phone)
    |> LoginPage.get_code()
    |> assert_has(LoginPage.authentication_code_instructions())

    # Find the auth token sent to user via SMS
    authentication_code = LoginPage.get_authentication_code()

    session
    |> LoginPage.fill_in_authentication_code(authentication_code)
    |> LoginPage.click_sign_in()

    assert current_path(session) == "/campaigns"
  end
end
