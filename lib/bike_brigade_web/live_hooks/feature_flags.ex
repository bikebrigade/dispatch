defmodule BikeBrigadeWeb.LiveHooks.FeatureFlags do
  @moduledoc """
  Gates a LiveView behind one of the current user's `BikeBrigade.Accounts.User.Flags`.

      on_mount {BikeBrigadeWeb.LiveHooks.FeatureFlags, {:require, :unified_messaging, "/messages"}}

  Users without the flag are sent to the given path with a flash message. Must run after a hook that
  assigns `:current_user`.
  """
  import Phoenix.LiveView

  def on_mount({:require, flag, redirect_to}, _params, _session, socket) do
    if Map.get(socket.assigns.current_user.flags, flag) do
      {:cont, socket}
    else
      {:halt,
       socket
       |> put_flash(:error, "That page isn't enabled for your account yet")
       |> push_navigate(to: redirect_to)}
    end
  end
end
