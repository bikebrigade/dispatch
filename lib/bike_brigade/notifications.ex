defmodule BikeBrigade.Notifications do
  @moduledoc """
  The Notifications context.
  """
  import Ecto.Query, warn: false
  alias BikeBrigade.Repo

  alias BikeBrigade.Notifications.Banner

  ## Banner Functions

  def update_banner(%Banner{} = banner, attrs) do
    banner
    |> Banner.changeset(attrs)
    |> Repo.update()
    |> broadcast(:banner_updated)
  end

  def create_banner(banner \\ %Banner{}, attrs) do
    banner
    |> Banner.changeset(attrs)
    |> Repo.insert()
    |> broadcast(:banner_created)
  end

  def list_banners() do
    Repo.all(Banner)
  end

  def new_banner() do
    %Banner{}
  end

  def banner_changeset(banner \\ %Banner{}, attrs) do
    banner
    |> Banner.changeset(attrs)
  end

  def get_banner!(id), do: Repo.get!(Banner, id)

  def delete_banner(%Banner{} = banner) do
    Repo.delete(banner)
    |> broadcast(:banner_deleted)
  end

  @doc """
  Returns currently active banners.

  A banner is considered active if:
  - It is enabled
  - The current time is between turn_on_at and turn_off_at
  """
  def list_active_banners() do
    now = DateTime.utc_now()

    from(b in Banner,
      where: b.enabled == true,
      where: b.turn_on_at <= ^now,
      where: b.turn_off_at >= ^now,
      order_by: [asc: b.turn_on_at]
    )
    |> Repo.all()
  end

  @doc """
  Renders a banner message with URLs converted to clickable links.
  """
  def render_banner_message(%Banner{message: message}) do
    Linkify.link(message, class: "link break-all", new_window: true)
  end

  def subscribe do
    Phoenix.PubSub.subscribe(BikeBrigade.PubSub, "notifications")
  end

  defp broadcast({:error, _reason} = error, _event), do: error

  defp broadcast({:ok, struct}, event) do
    Phoenix.PubSub.broadcast(BikeBrigade.PubSub, "notifications", {event, struct})
    {:ok, struct}
  end
end
