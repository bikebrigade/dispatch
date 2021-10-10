defmodule BikeBrigadeWeb.ErrorView do
  use BikeBrigadeWeb, :view

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
