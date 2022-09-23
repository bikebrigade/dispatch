defmodule BikeBrigade.Riders.Helpers do
  alias BikeBrigade.Riders.Rider
  alias BikeBrigade.Delivery.Task

  def first_name(%Rider{name: name}) do
    # TODO make this work with non-western names
    if name do
      name
      |> String.split()
      |> List.first()
    end
  end

  def first_name(%Task{} = task) do
    # TODO make this work with non-western names
    task.dropoff_name
    |> String.split()
    |> List.first()
  end
end
