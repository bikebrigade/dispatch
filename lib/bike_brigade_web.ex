defmodule BikeBrigadeWeb do
  @moduledoc """
  The entrypoint for defining your web interface, such
  as controllers, views, channels and so on.

  This can be used in your application as:

      use BikeBrigadeWeb, :controller
      use BikeBrigadeWeb, :view

  The definitions below will be executed for every view,
  controller, etc, so keep them short and clean, focused
  on imports, uses and aliases.

  Do NOT define functions inside the quoted expressions
  below. Instead, define any helper function in modules
  and import those modules here.
  """

  def static_paths, do: ~w(assets fonts images favicon.png favicon_dev.png robots.txt)

  def controller do
    quote do
      use Phoenix.Controller, namespace: BikeBrigadeWeb

      import Plug.Conn
      import BikeBrigadeWeb.Gettext

      unquote(verified_routes())
    end
  end

  def view do
    quote do
      use Phoenix.View,
        root: "lib/bike_brigade_web/templates",
        namespace: BikeBrigadeWeb

      use Phoenix.Component

      # Import convenience functions from controllers
      import Phoenix.Controller,
        only: [get_csrf_token: 0, get_flash: 1, get_flash: 2, view_module: 1]

      # Include shared imports and aliases for views
      unquote(view_helpers())
    end
  end

  def live_view(opts \\ [layout: {BikeBrigadeWeb.LayoutView, "app.html"}]) do
    quote do
      use Phoenix.LiveView, unquote(opts)

      unquote(view_helpers())
    end
  end

  def live_component do
    quote do
      use Phoenix.LiveComponent

      unquote(view_helpers())
    end
  end

  def component do
    quote do
      use Phoenix.Component

      unquote(view_helpers())
    end
  end

  def router do
    quote do
      use Phoenix.Router, helpers: false

      import Plug.Conn
      import Phoenix.Controller
      import Phoenix.LiveView.Router
    end
  end

  def channel do
    quote do
      use Phoenix.Channel
      import BikeBrigadeWeb.Gettext
    end
  end

  def verified_routes do
    quote do
      use Phoenix.VerifiedRoutes,
        endpoint: BikeBrigadeWeb.Endpoint,
        router: BikeBrigadeWeb.Router,
        statics: BikeBrigadeWeb.static_paths()
    end
  end

  defp view_helpers do
    quote do
      # Use all HTML functionality (forms, tags, etc)
      use Phoenix.HTML

      import BikeBrigadeWeb.Components
      # TODO remove this?
      import BikeBrigadeWeb.LiveHelpers

      # Import basic rendering functionality (render, render_layout, etc)
      import Phoenix.View

      import BikeBrigadeWeb.ErrorHelpers
      import BikeBrigadeWeb.Gettext

      # Alias in JS
      alias Phoenix.LiveView.JS

      # Alias in components
      alias BikeBrigadeWeb.Components, as: C
      alias BikeBrigadeWeb.Components.UI

      unquote(verified_routes())
    end
  end

  @doc """
  When used, dispatch to the appropriate controller/view/etc.
  """
  defmacro __using__(which) when is_atom(which) do
    apply(__MODULE__, which, [])
  end

  defmacro __using__({which, opts}) when is_atom(which) do
    apply(__MODULE__, which, [opts])
  end
end
