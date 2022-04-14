defmodule BikeBrigade.SingleGlobalGenServer do
  defmacro __using__(opts \\ []) do
    initial_state = Keyword.get(opts, :initial_state, %{})

    quote do
      use GenServer

      require Logger

      Module.put_attribute(
        __MODULE__,
        :name,
        {:via, Horde.Registry, {BikeBrigade.HordeRegistry, __MODULE__}}
      )

      def start_link([]) do
        # When we are in non-distributed mode start us using Horde
        Horde.DynamicSupervisor.start_child(
          BikeBrigade.HordeSupervisor,
          {__MODULE__, distributed: true}
        )

        # Ignore since this is called from the main supervisor
        :ignore
      end

      def start_link(distributed: true) do
        case GenServer.start_link(__MODULE__, unquote(initial_state), name: @name) do
          {:ok, pid} ->
            Logger.info("#{inspect(__MODULE__)}: Starting at #{inspect(pid)}")
            {:ok, pid}

          {:error, {:already_started, pid}} ->
            Logger.info(
              "#{inspect(__MODULE__)}: already started at #{inspect(pid)}, returning :ignore"
            )

            :ignore
        end
      end
    end
  end
end
