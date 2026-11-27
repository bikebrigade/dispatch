defmodule BikeBrigadeWeb.BannerComponents do
  use Phoenix.Component

  alias BikeBrigade.Notifications

  @doc """
  Renders a banner's message the way riders see it: URLs become links, line
  breaks are kept, and links written as HTML get the same link styling.
  """
  attr :banner, :any, required: true
  attr :class, :any, default: nil

  def banner_message(assigns) do
    # phx-no-format: whitespace-pre-line would render the formatter's
    # indentation around the message as blank lines.
    ~H"""
    <div
      class={["whitespace-pre-line [&_a]:text-primary [&_a]:underline [&_a]:break-all", @class]}
      phx-no-format
    >{Phoenix.HTML.raw(Notifications.render_banner_message(@banner))}</div>
    """
  end
end
