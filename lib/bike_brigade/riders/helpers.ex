defmodule BikeBrigade.Riders.Helpers do
  alias BikeBrigade.Riders.Rider
  alias BikeBrigade.Delivery.Task

  def first_name(%Rider{} = rider) do
    # TODO make this work with non-western names
    rider.name
    |> String.split()
    |> List.first()
  end

  def first_name(%Task{} = task) do
    # TODO make this work with non-western names
    task.dropoff_name
    |> String.split()
    |> List.first()
  end
end
