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

  describe "Backup Riders" do
    setup do
      campaign = fixture(:campaign)
      rider = fixture(:rider, %{name: "Jane Doe"})
      backup_rider = fixture(:rider, %{name: "John Smith"})

      %{campaign: campaign, rider: rider, backup_rider: backup_rider}
    end

    test "create_backup_campaign_rider/1 creates backup rider", %{
      campaign: campaign,
      backup_rider: rider
    } do
      attrs = %{
        "campaign_id" => campaign.id,
        "rider_id" => rider.id,
        "rider_capacity" => "1",
        "pickup_window" => "10:00-11:00AM",
        "enter_building" => true,
        "rider_signed_up" => true
      }

      assert {:ok, campaign_rider} = Delivery.create_backup_campaign_rider(attrs)
      assert campaign_rider.backup_rider == true
      assert campaign_rider.rider_id == rider.id
      assert campaign_rider.campaign_id == campaign.id
    end

    test "get_backup_riders/1 returns only backup riders", %{
      campaign: campaign,
      rider: regular_rider,
      backup_rider: backup_rider
    } do
      # Create a regular campaign rider
      {:ok, _regular_cr} =
        Delivery.create_campaign_rider(%{
          "campaign_id" => campaign.id,
          "rider_id" => regular_rider.id,
          "rider_capacity" => "1",
          "pickup_window" => "10:00-11:00AM",
          "enter_building" => true,
          "rider_signed_up" => true
        })

      # Create a backup campaign rider
      {:ok, _backup_cr} =
        Delivery.create_backup_campaign_rider(%{
          "campaign_id" => campaign.id,
          "rider_id" => backup_rider.id,
          "rider_capacity" => "1",
          "pickup_window" => "10:00-11:00AM",
          "enter_building" => true,
          "rider_signed_up" => true
        })

      backup_riders = Delivery.get_backup_riders(campaign)

      assert length(backup_riders) == 1
      assert hd(backup_riders).id == backup_rider.id
    end

    test "campaign_riders_and_tasks/1 excludes backup riders", %{
      campaign: campaign,
      rider: regular_rider,
      backup_rider: backup_rider
    } do
      # Create a regular campaign rider
      {:ok, _regular_cr} =
        Delivery.create_campaign_rider(%{
          "campaign_id" => campaign.id,
          "rider_id" => regular_rider.id,
          "rider_capacity" => "1",
          "pickup_window" => "10:00-11:00AM",
          "enter_building" => true,
          "rider_signed_up" => true
        })

      # Create a backup campaign rider
      {:ok, _backup_cr} =
        Delivery.create_backup_campaign_rider(%{
          "campaign_id" => campaign.id,
          "rider_id" => backup_rider.id,
          "rider_capacity" => "1",
          "pickup_window" => "10:00-11:00AM",
          "enter_building" => true,
          "rider_signed_up" => true
        })

      {riders, _tasks} = Delivery.campaign_riders_and_tasks(campaign)

      assert length(riders) == 1
      assert hd(riders).id == regular_rider.id
    end

    test "remove_backup_rider_from_campaign/2 removes backup rider", %{
      campaign: campaign,
      backup_rider: backup_rider
    } do
      # Create a backup campaign rider
      {:ok, _backup_cr} =
        Delivery.create_backup_campaign_rider(%{
          "campaign_id" => campaign.id,
          "rider_id" => backup_rider.id,
          "rider_capacity" => "1",
          "pickup_window" => "10:00-11:00AM",
          "enter_building" => true,
          "rider_signed_up" => true
        })

      # Verify backup rider exists
      backup_riders = Delivery.get_backup_riders(campaign)
      assert length(backup_riders) == 1

      # Remove backup rider
      assert {:ok, _} = Delivery.remove_backup_rider_from_campaign(campaign, backup_rider.id)

      # Verify backup rider is removed
      backup_riders = Delivery.get_backup_riders(campaign)
      assert length(backup_riders) == 0
    end

    test "remove_backup_rider_from_campaign/2 returns error if backup rider not found", %{
      campaign: campaign,
      backup_rider: backup_rider
    } do
      assert {:error, :not_found} =
               Delivery.remove_backup_rider_from_campaign(campaign, backup_rider.id)
    end

    test "remove_backup_rider_from_campaign/2 only removes backup riders, not regular riders", %{
      campaign: campaign,
      rider: regular_rider,
      backup_rider: backup_rider
    } do
      # Create a regular campaign rider
      {:ok, _regular_cr} =
        Delivery.create_campaign_rider(%{
          "campaign_id" => campaign.id,
          "rider_id" => regular_rider.id,
          "rider_capacity" => "1",
          "pickup_window" => "10:00-11:00AM",
          "enter_building" => true,
          "rider_signed_up" => true
        })

      # Try to remove as backup rider (should fail since they're not a backup rider)
      assert {:error, :not_found} =
               Delivery.remove_backup_rider_from_campaign(campaign, regular_rider.id)

      # Verify regular rider still exists
      {riders, _tasks} = Delivery.campaign_riders_and_tasks(campaign)
      assert length(riders) == 1
      assert hd(riders).id == regular_rider.id
    end

    test "backup riders cannot sign up for regular tasks via signup_rider event", %{
      campaign: campaign,
      backup_rider: backup_rider
    } do
      # Create a backup campaign rider
      {:ok, _backup_cr} =
        Delivery.create_backup_campaign_rider(%{
          "campaign_id" => campaign.id,
          "rider_id" => backup_rider.id,
          "rider_capacity" => "1",
          "pickup_window" => "10:00-11:00AM",
          "enter_building" => true,
          "rider_signed_up" => true
        })

      # Create a task
      task = fixture(:task, %{campaign: campaign})

      # Try to create a regular campaign rider for the backup rider (this should fail)
      attrs = %{
        "campaign_id" => campaign.id,
        "rider_id" => backup_rider.id,
        "rider_capacity" => "1",
        "pickup_window" => "10:00-11:00AM",
        "enter_building" => true,
        "rider_signed_up" => true
      }

      # This should fail since backup rider already exists
      assert {:error, changeset} = Delivery.create_campaign_rider(attrs)
      assert {"already signed up as backup rider", []} = changeset.errors[:rider_id]
    end

    test "create_campaign_rider_without_backup_check/1 allows conversion of backup riders", %{
      campaign: campaign,
      backup_rider: backup_rider
    } do
      # Create a backup campaign rider
      {:ok, _backup_cr} =
        Delivery.create_backup_campaign_rider(%{
          "campaign_id" => campaign.id,
          "rider_id" => backup_rider.id,
          "rider_capacity" => "3",
          "pickup_window" => "10:00-11:00AM",
          "enter_building" => true,
          "rider_signed_up" => true
        })

      # Should be able to create regular campaign rider even though backup exists
      # (this simulates the conversion process)
      attrs = %{
        "campaign_id" => campaign.id,
        "rider_id" => backup_rider.id,
        "rider_capacity" => "3",
        "pickup_window" => "10:00-11:00AM",
        "enter_building" => true,
        "rider_signed_up" => true
      }

      assert {:ok, regular_cr} = Delivery.create_campaign_rider_without_backup_check(attrs)
      assert regular_cr.backup_rider == false
      assert regular_cr.rider_id == backup_rider.id
      assert regular_cr.rider_capacity == 3
    end
  end

  def item_name(%Task{task_items: [%{item: %{name: item_name}}]}), do: item_name
end
