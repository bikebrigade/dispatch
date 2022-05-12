defmodule BikeBrigade.MailchimpApi.FakeMailchimp do
  alias BikeBrigade.MailchimpApi
  use GenServer

  @behaviour MailchimpApi

  def start_link(_opts \\ []) do
    GenServer.start_link(__MODULE__, %{}, name: __MODULE__)
  end

  @impl MailchimpApi
  def get_list(list_id, opted_in \\ nil) do
    GenServer.call(__MODULE__, {:get_list, list_id, opted_in})
  end

  def add_members(list_id, members) do
    GenServer.cast(__MODULE__, {:add_members, list_id, members})
  end

  def clear_members(list_id) do
    GenServer.cast(__MODULE__, {:clear_members, list_id})
  end

  @impl GenServer
  def init(members) do
    {:ok, members}
  end

  @impl GenServer
  def handle_call({:get_list, list_id, nil}, _from, lists) do
    members =
      Map.get(lists, list_id, [])
      |> Enum.map(fn {_inserted_at, member} -> member end)

    {:reply, {:ok, members}, lists}
  end

  def handle_call({:get_list, list_id, opted_in}, _from, lists) do
    case DateTime.from_iso8601(opted_in) do
      {:ok, opted_in, _offset} ->
        members =
          for {inserted_at, member} <- Map.get(lists, list_id, []),
              :gt == DateTime.compare(inserted_at, opted_in) do
            member
          end

        {:reply, {:ok, members}, lists}

      {:error, _} ->
        {:reply, {:error, :invalid_opted_in}, lists}
    end
  end

  @impl GenServer
  def handle_cast({:add_members, list_id, members}, lists) do
    inserted_at = DateTime.utc_now()

    updates =
      for member <- members do
        {inserted_at, member}
      end

    {:noreply, Map.update(lists, list_id, updates, fn l -> l ++ updates end)}
  end

  def handle_cast({:clear_members, list_id}, lists) do
    {:noreply, Map.delete(lists, list_id)}
  end
end
