defmodule BikeBrigade.FeatureTestPages.LoginPage do
  alias Wallaby.Browser
  alias Wallaby.Query
  alias BikeBrigade.SmsService.FakeSmsService

  def visit(session) do
    session
    |> Browser.visit("/login")
  end

  def sign_in_prompt() do
    Query.css("h2", text: "Sign in to your account")
  end

  def phone_number_field() do
    Query.text_field("Phone number")
  end

  def get_code_button() do
    Query.button("Get Code")
  end

  def authentication_code_instructions() do
    Query.css("*[role=notice]", text: "We sent an authentication code to your phone number")
  end

  def auth_code_field() do
    Query.text_field("Authentication code")
  end

  def sign_in_button() do
    Query.button("Sign in")
  end

  def fill_in_phone_number(session, phone_number) do
    session
    |> Browser.fill_in(phone_number_field(), with: phone_number)
  end

  def get_code(session) do
    session
    |> Browser.click(get_code_button())
  end

  def get_authentication_code() do
    message =
      FakeSmsService.last_message()
      |> Keyword.fetch!(:body)

    [_, authentication_code] = Regex.run(~r[Your BikeBrigade access code is (\d+)\.], message)

    authentication_code
  end

  def fill_in_authentication_code(session, authentication_code \\ get_authentication_code()) do
    session
    |> Browser.fill_in(auth_code_field(), with: authentication_code)
  end

  def click_sign_in(session) do
    session
    |> Browser.click(sign_in_button())
  end
end
