defmodule BikeBrigade.UtilsTest do
  use ExUnit.Case, async: true

  alias BikeBrigade.Utils
  alias BikeBrigade.Delivery.Task
  alias BikeBrigade.Riders.Rider

  test "replace_if_updated/2" do
    task = %Task{id: 123, contact_name: "foo"}
    task_updated = %Task{id: 123, contact_name: "bar"}
    task2 = %Task{id: 345, contact_name: "baz"}
    rider = %Rider{id: 123, name: "foo"}

    # Update if the id is the same
    assert Utils.replace_if_updated(task, task_updated) == task_updated
    assert Utils.replace_if_updated(task, task2) == task

    # Only update the same structs
    assert Utils.replace_if_updated(task, rider) == task

    # Handle nils
    assert Utils.replace_if_updated(task, nil) == task
    assert Utils.replace_if_updated(nil, task) == nil
  end

  test "Can change a url's scheme" do
    assert Utils.change_scheme("http://example.com", "https") == "https://example.com"
    assert Utils.change_scheme("https://example.com", "http") == "http://example.com"
    assert Utils.change_scheme("https://example.com", "https") == "https://example.com"
    assert Utils.change_scheme("http://example.com", "http") == "http://example.com"

    assert Utils.change_scheme("http://example.com?foo=http%3A%2F%2Ffoo.com", "https") ==
             "https://example.com?foo=http%3A%2F%2Ffoo.com"
  end
end
