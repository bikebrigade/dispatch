defmodule BikeBrigadeWeb.ErrorHTML do
  use BikeBrigadeWeb, :html

  # If you want to customize your error pages,
  # uncomment the embed_templates/1 call below
  # and add pages to the error directory:
  #
  #   * lib/<%= @lib_web_name %>/controllers/error/404.html.heex
  #   * lib/<%= @lib_web_name %>/controllers/error/500.html.heex
  #
  # embed_templates "error/*"

  # The default is to render a plain text page based on
  # the template name. For example, "404.html" becomes
  # "Not Found".

  def render("403.html", %{reason: %BikeBrigadeWeb.DeliveryExpiredError{}}) do
    "This delivery is now over. Thank you for riding with The Bike Brigade!"
  end

  # By default, Phoenix returns the status message from
  # the template name. For example, "404.html" becomes
  # "Not Found".
  def template_not_found(template, _assigns) do
    Phoenix.Controller.status_message_from_template(template)
  end
end
