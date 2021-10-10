defmodule BikeBrigade.Adapter do
  defmacro __using__(cfg_section) do
    {module, args} =
      BikeBrigade.Utils.fetch_env!(cfg_section, :adapter)
      |> extract_module_and_args()

    quote do
      # Generate a module attribute that exposes the module
      Module.put_attribute(
        __MODULE__,
        unquote(cfg_section),
        unquote(module)
      )

      @doc """
      Add a child spec to `children` if the adapter
      needs to start a process, otherwise pass it through unchanged.
      """
      @spec append_child_spec(list) :: list
      def append_child_spec(children) when is_list(children) do
        module = unquote(module)
        args = unquote(args)

        case Kernel.function_exported?(module, :start_link, 1) do
          true -> children ++ [{module, args}]
          false -> children
        end
      end

      @doc """
      Expose the dynamically configured adapter
      """
      def adapter(), do: unquote(module)
    end
  end

  defp extract_module_and_args(module) when is_atom(module), do: {module, []}

  defp extract_module_and_args({module, args}) when is_atom(module) and is_list(args),
    do: {module, args}
end
