defmodule BikeBrigade.DeliveryTest do
  use BikeBrigade.DataCase

  alias BikeBrigade.{LocalizedDateTime, Delivery, Delivery.Task, History}

  use Phoenix.VerifiedRoutes, endpoint: BikeBrigadeWeb.Endpoint, router: BikeBrigadeWeb.Router

  describe "Campaign Messaging" do
    setup do
      program = fixture(:program, %{name: "ACME Delivery"})

      campaign =
        fixture(:campaign, %{
          program_id: program.id,
          delivery_start: LocalizedDateTime.localize(~N[2023-01-01 10:00:00]),
          delivery_end: LocalizedDateTime.localize(~N[2023-01-01 11:00:00])
        })

      rider = fixture(:rider, %{name: "Hannah Bannana"})
      task = fixture(:task, %{campaign: campaign, rider: rider})

      %{campaign: campaign, rider: rider, task: task}
    end

    test "render_campaign_message_for_rider/3", %{campaign: campaign} do
      {[rider], [task]} = Delivery.campaign_riders_and_tasks(campaign)

      message = """
      Hello Hannah,
      Thanks for signing up for {{program_name}} at {{{pickup_address}}} on {{{delivery_date}}} at {{{pickup_window}}}.  You'll be delivering {{{task_count}}}

      Here is your delivery link: {{{delivery_details_url}}}

      Also here are the details:

      {{{task_details}}}

      Directions: {{{directions}}}
      """

      directions_url =
        BikeBrigade.GoogleMaps.directions_url(rider.location, [
          campaign.location,
          task.dropoff_location
        ])

      assert Delivery.render_campaign_message_for_rider(campaign, message, rider) ==
               """
               Hello #{BikeBrigade.Riders.Helpers.first_name(rider)},
               Thanks for signing up for ACME Delivery at #{task.pickup_location} on Sun Jan 1st at 10:00-11:00AM.  You'll be delivering 1 #{item_name(task)}

               Here is your delivery link: #{url(~p"/app/delivery/#{rider.delivery_url_token}")}

               Also here are the details:

               Name: #{task.dropoff_name}
               Phone: #{task.dropoff_phone}
               Type: 1 #{item_name(task)}
               Address: #{task.dropoff_location}
               Notes: #{task.delivery_instructions}

               Directions: #{directions_url}
               """
    end
  end

  test "assign_task/3" do
    campaign = fixture(:campaign)
    rider = fixture(:rider)
    user = fixture(:user)
    task = fixture(:task, %{campaign: campaign})

    assert {:ok, task} = Delivery.assign_task(task, rider.id, user.id)

    assert task.assigned_rider_id == rider.id

    assert [log] = History.list_task_assignment_logs()
    assert log.task_id == task.id
    assert log.rider_id == rider.id
    assert log.user_id == user.id
    assert log.action == :assigned
  end

  test "unassign_task/3" do
    campaign = fixture(:campaign)
    rider = fixture(:rider)
    user = fixture(:user)
    task = fixture(:task, %{campaign: campaign, assigned_rider_id: rider.id})

    assert {:ok, task} = Delivery.unassign_task(task, user.id)

    assert task.assigned_rider_id == nil

    assert [log] = History.list_task_assignment_logs()
    assert log.task_id == task.id
    assert log.rider_id == rider.id
    assert log.user_id == user.id
    assert log.action == :unassigned
  end

  def item_name(%Task{task_items: [%{item: %{name: item_name}}]}), do: item_name

  defp to_uri(location) do
    location
    |> String.Chars.to_string()
    |> URI.encode_www_form()
  end

  describe "announcements" do
    alias BikeBrigade.Delivery.Announcement

    import BikeBrigade.DeliveryFixtures

    @invalid_attrs %{message: nil, turn_on_at: nil, turn_off_at: nil}

    test "list_announcements/0 returns all announcements" do
      announcement = announcement_fixture()
      assert Delivery.list_announcements() == [announcement]
    end

    test "get_announcement!/1 returns the announcement with given id" do
      announcement = announcement_fixture()
      assert Delivery.get_announcement!(announcement.id) == announcement
    end

    test "create_announcement/1 with valid data creates a announcement" do
      valid_attrs = %{message: "some message", turn_on_at: ~U[2025-02-10 22:26:00.000000Z], turn_off_at: ~U[2025-02-10 22:26:00.000000Z]}

      assert {:ok, %Announcement{} = announcement} = Delivery.create_announcement(valid_attrs)
      assert announcement.message == "some message"
      assert announcement.turn_on_at == ~U[2025-02-10 22:26:00.000000Z]
      assert announcement.turn_off_at == ~U[2025-02-10 22:26:00.000000Z]
    end

    test "create_announcement/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Delivery.create_announcement(@invalid_attrs)
    end

    test "update_announcement/2 with valid data updates the announcement" do
      announcement = announcement_fixture()
      update_attrs = %{message: "some updated message", turn_on_at: ~U[2025-02-11 22:26:00.000000Z], turn_off_at: ~U[2025-02-11 22:26:00.000000Z]}

      assert {:ok, %Announcement{} = announcement} = Delivery.update_announcement(announcement, update_attrs)
      assert announcement.message == "some updated message"
      assert announcement.turn_on_at == ~U[2025-02-11 22:26:00.000000Z]
      assert announcement.turn_off_at == ~U[2025-02-11 22:26:00.000000Z]
    end

    test "update_announcement/2 with invalid data returns error changeset" do
      announcement = announcement_fixture()
      assert {:error, %Ecto.Changeset{}} = Delivery.update_announcement(announcement, @invalid_attrs)
      assert announcement == Delivery.get_announcement!(announcement.id)
    end

    test "delete_announcement/1 deletes the announcement" do
      announcement = announcement_fixture()
      assert {:ok, %Announcement{}} = Delivery.delete_announcement(announcement)
      assert_raise Ecto.NoResultsError, fn -> Delivery.get_announcement!(announcement.id) end
    end

    test "change_announcement/1 returns a announcement changeset" do
      announcement = announcement_fixture()
      assert %Ecto.Changeset{} = Delivery.change_announcement(announcement)
    end
  end
end
