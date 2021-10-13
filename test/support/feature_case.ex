defmodule BikeBrigadeWeb.FeatureCase do
  use ExUnit.CaseTemplate

  using do
    quote do
      use Wallaby.DSL
      import BikeBrigade.Fixtures
      alias BikeBrigadeWeb.Router.Helpers, as: Routes

      @endpoint BikeBrigadeWeb.Endpoint
    end
  end

  setup tags do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(BikeBrigade.Repo)

    unless tags[:async] do
      Ecto.Adapters.SQL.Sandbox.mode(BikeBrigade.Repo, {:shared, self()})
    end

    metadata = Phoenix.Ecto.SQL.Sandbox.metadata_for(BikeBrigade.Repo, self())
    {:ok, session} = Wallaby.start_session(metadata: metadata)
    {:ok, session: session}
  end
end
