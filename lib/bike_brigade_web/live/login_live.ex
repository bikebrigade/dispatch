defmodule BikeBrigadeWeb.LoginLive do
  use BikeBrigadeWeb, {:live_view, layout: {BikeBrigadeWeb.LayoutView, "public.live.html"}}
  use Phoenix.HTML

  alias BikeBrigade.AuthenticationMessenger
  alias BikeBrigade.Accounts

  defmodule Login do
    use BikeBrigade.Schema
    import Ecto.Changeset

    alias BikeBrigade.EctoPhoneNumber

    @primary_key false
    embedded_schema do
      field :phone, EctoPhoneNumber.Canadian
      field :token_attempt, :string
    end

    def validate_phone(attrs) do
      %Login{}
      |> cast(attrs, [:phone])
      |> validate_required([:phone])
      |> validate_user_exists(:phone)
      |> Ecto.Changeset.apply_action(:insert)
    end

    defp validate_user_exists(changeset, field) when is_atom(field) do
      validate_change(changeset, field, fn _, phone ->
        case Accounts.get_user_by_phone(phone) do
          nil -> [{field, "We can't find your number. Have you signed up for Bike Brigade?"}]
          _ -> []
        end
      end)
    end
  end

  @impl Phoenix.LiveView
  def mount(_params, _session, socket) do
    {:ok, assign(socket, page_title: "Login")}
  end

  @impl Phoenix.LiveView
  def handle_params(%{"phone" => phone}, _uri, socket) do
    {:noreply,
     socket
     |> assign(:state, :token)
     |> assign(:changeset, Ecto.Changeset.change(%Login{phone: phone}))}
  end

  @impl Phoenix.LiveView
  def handle_params(_params, _uri, socket) do
    {:noreply,
     socket
     |> assign(:state, :phone)
     |> assign(:changeset, Ecto.Changeset.change(%Login{}))}
  end

  @impl Phoenix.LiveView
  def handle_event("submit-phone", %{"login" => attrs}, socket) do
    with {:ok, login} <- Login.validate_phone(attrs),
         :ok <- AuthenticationMessenger.generate_token(login.phone) do
      {:noreply, assign(socket, state: :token, changeset: Ecto.Changeset.change(login))}
    else
      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, changeset: changeset)}

      {:error, err} ->
        {:noreply,
         socket
         |> put_flash(:error, err)
         |> push_patch(to: ~p"/login")}
    end
  end
end
