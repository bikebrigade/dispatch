defmodule BikeBrigadeWeb.Components.UI do
  use Phoenix.Component
  use Phoenix.HTML
  alias Phoenix.LiveView.JS

  def table(assigns) do
    assigns =
      assigns
      |> assign_new(:class, fn -> "min-w-full" end)
      |> assign_new(:footer, fn -> [] end)
      |> then(&assign(&1, :attrs, assigns_to_attributes(&1, [:th, :td, :rows, :footer])))

    ~H"""
    <div class="flex flex-col py-4">
      <div class="py-2 -my-2 overflow-x-auto sm:-mx-6 sm:px-6 lg:-mx-8 lg:px-8">
        <div class="inline-block min-w-full overflow-hidden align-middle border-b border-gray-200 shadow sm:rounded-lg">
          <table {@attrs}>
            <thead>
              <tr>
                <%= for th <- @th do %>
                  <th class={
                    "text-xs font-medium leading-4 tracking-wider text-left text-gray-500 border-b border-gray-200 bg-gray-50 #{if Map.get(th, :uppercase, true), do: "uppercase"} #{Map.get(th, :padding, "px-6 py-3")} #{Map.get(th, :class)}"
                  }>
                    <%= render_slot(th) %>
                  </th>
                <% end %>
              </tr>
            </thead>
            <tbody class="bg-white">
              <%= for row <- @rows do %>
                <tr>
                  <%= for td <- @td do %>
                    <td class={
                      "text-sm leading-5 text-gray-500 border-b border-gray-200 whitespace-nowrap #{Map.get(td, :padding, "px-6 py-4")} #{Map.get(td, :class)}"
                    }>
                      <%= render_slot(td, row) %>
                    </td>
                  <% end %>
                </tr>
              <% end %>
            </tbody>
          </table>
          <%= render_slot(@footer) %>
        </div>
      </div>
    </div>
    """
  end
end
