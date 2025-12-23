defmodule BikeBrigadeWeb do
  @moduledoc """
  The entrypoint for defining your web interface, such
  as controllers, components, channels, and so on.

  This can be used in your application as:

      use BikeBrigadeWeb, :controller
      use BikeBrigadeWeb, :html

  The definitions below will be executed for every controller,
  component, etc, so keep them short and clean, focused
  on imports, uses and aliases.

  Do NOT define functions inside the quoted expressions
  below. Instead, define any helper function in modules
  and import those modules here.
  """

  def static_paths, do: ~w(assets fonts images favicon.png favicon_dev.png robots.txt)

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
      use Gettext, backend: BikeBrigadeWeb.Gettext
    end
  end

  def controller do
    quote do
      use Phoenix.Controller,
        namespace: BikeBrigadeWeb,
        formats: [:html, :json],
        layouts: [html: BikeBrigadeWeb.Layouts]

      import Plug.Conn
      use Gettext, backend: BikeBrigadeWeb.Gettext

      unquote(verified_routes())
    end
  end

  def live_view(opts \\ []) do
    layout = Keyword.get(opts, :layout, :app)

    quote do
      use Phoenix.LiveView, layout: {BikeBrigadeWeb.Layouts, unquote(layout)}

      unquote(html_helpers())
    end
  end

  def live_component do
    quote do
      use Phoenix.LiveComponent

      unquote(html_helpers())
    end
  end

  def html do
    quote do
      use Phoenix.Component

      # Import convenience functions from controllers
      import Phoenix.Controller,
        only: [get_csrf_token: 0, view_module: 1, view_template: 1]

      # Include shared imports and aliases for views
      unquote(html_helpers())
    end
  end

  def component do
    quote do
      use Phoenix.Component

      unquote(html_helpers())
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

  defp html_helpers do
    quote do
      # HTML escaping functionality
      import Phoenix.HTML
      import Phoenix.HTML.Form
      use PhoenixHTMLHelpers

      # Core UI components and translation
      import BikeBrigadeWeb.CoreComponents
      use Gettext, backend: BikeBrigadeWeb.Gettext

      # TODO remove this?
      import BikeBrigadeWeb.LiveHelpers
      import BikeBrigadeWeb.ErrorHelpers

      # Shortcut for generating JS commands
      alias Phoenix.LiveView.JS

      # Alias in components
      alias BikeBrigadeWeb.CoreComponents

      alias BikeBrigadeWeb.Components.{
        Icons,
        RiderSelectionComponent,
        UserSelectionComponent
      }

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
