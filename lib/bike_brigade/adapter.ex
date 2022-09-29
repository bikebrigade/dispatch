defmodule BikeBrigade.Adapter do
  defmacro __using__(cfg_section) do
    quote do
      @doc """
      Expose the dynamically configured adapter
      """
      def adapter() do
        BikeBrigade.Adapter.Utils.extract_adapter(unquote(cfg_section))
      end

      @doc """
      Add a child spec to `children` if the adapter
      needs to start a process, otherwise pass it through unchanged.
      """
      @spec append_child_spec(list) :: list
      def append_child_spec(children) when is_list(children) do
        module = BikeBrigade.Adapter.Utils.extract_adapter(unquote(cfg_section))
        args = BikeBrigade.Adapter.Utils.extract_adapter_args(unquote(cfg_section))
        case Code.ensure_loaded!(module) && Kernel.function_exported?(module, :start_link, 1) do
          true -> children ++ [{module, args}]
          false -> children
        end
      end
    end
  end

  defmodule Utils do
    def extract_adapter(cfg_section) do
      case BikeBrigade.Utils.fetch_env!(cfg_section, :adapter) do
        module when is_atom(module) -> module
        {module, _} when is_atom(module) -> module
      end
    end

    def extract_adapter_args(cfg_section) do
      case BikeBrigade.Utils.fetch_env!(cfg_section, :adapter) do
        module when is_atom(module) -> []
        {module, args} when is_atom(module) and is_list(args) -> args
      end
    end
  end
end
