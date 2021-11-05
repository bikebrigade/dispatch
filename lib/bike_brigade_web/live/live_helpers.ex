defmodule BikeBrigadeWeb.LiveHelpers do
  import Phoenix.LiveView.Helpers

  import Phoenix.LiveView, [:assign_new / 3]

  alias BikeBrigade.LocalizedDateTime

  alias BikeBrigade.Accounts

  @doc """
  Renders a component inside the `BikeBrigadeWeb.Components.ModalComponent` component.

  The rendered modal receives a `:return_to` option to properly update
  the URL when the modal is closed.

  ## Examples

      <%= live_modal BikeBrigadeWeb.RiderLive.FormComponent,
        id: @rider.id || :new,
        action: @live_action,
        rider: @rider,
        return_to: Routes.rider_index_path(@socket, :index) %>
  """
  def live_modal(component, opts) do
    path = Keyword.fetch!(opts, :return_to)
    modal_opts = [id: :modal, return_to: path, component: component, opts: opts]
    live_component(BikeBrigadeWeb.Components.ModalComponent, modal_opts)
  end

  def live_slideover(component, opts) do
    path = Keyword.fetch!(opts, :return_to)
    title = Keyword.fetch!(opts, :title)
    modal_opts = [id: :modal, title: title, return_to: path, component: component, opts: opts]
    live_component(BikeBrigadeWeb.Components.SlideoverComponent, modal_opts)
  end

  def gravatar(email) do
    hash =
      email
      |> String.trim()
      |> String.downcase()
      |> :erlang.md5()
      |> Base.encode16(case: :lower)

    "https://www.gravatar.com/avatar/#{hash}?s=150&d=identicon"
  end

  def assign_defaults(socket, %{"user_id" => user_id}) do
    # can this ever return nil?
    user = Accounts.get_user(user_id)

    # Set the context for Honeybadger here
    Honeybadger.context(context: %{user_id: user.id, user_email: user.email})

    socket
    |> assign_new(:current_user, fn -> user end)
    |> assign_new(:page_title, fn -> nil end)
  end

  def date(datetime) do
    LocalizedDateTime.localize(datetime)
    |> Calendar.strftime("%x")
  end

  def datetime(datetime) do
    LocalizedDateTime.localize(datetime)
    |> Calendar.strftime("%x %-I:%M%p")
  end

  def time_interval(start_datetime, end_datetime) do
    if start_datetime == end_datetime do
      LocalizedDateTime.localize(start_datetime)
      |> Calendar.strftime("%-I:%M%p")
    else
      s =
        LocalizedDateTime.localize(start_datetime)
        |> Calendar.strftime("%-I:%M")

      e =
        LocalizedDateTime.localize(end_datetime)
        |> Calendar.strftime("%-I:%M%p")

      "#{s}-#{e}"
    end
  end

  def lat(%Geo.Point{coordinates: {_lng, lat}}), do: lat
  def lat(_), do: nil

  def lng(%Geo.Point{coordinates: {lng, _lat}}), do: lng
  def lng(_), do: nil

  @doc """
  Round distance in metres to nearest .1km
  """
  def round_distance(metres) do
    round(metres / 100) / 10
  end

  @doc """
  Render content preserving spacing and phone numbers as links
  """
  def render_raw(content) when is_binary(content) do
    content
    |> Linkify.link(phone: true, class: "link break-all", new_window: true)
    |> Phoenix.HTML.raw()
  end

  def render_raw(nil), do: ""

  def favicon_path(conn) do
    if BikeBrigade.Utils.dev? do
      BikeBrigadeWeb.Router.Helpers.static_path(conn, "/favicon_dev.png")
    else
      BikeBrigadeWeb.Router.Helpers.static_path(conn, "/favicon.png")
    end
  end
end
