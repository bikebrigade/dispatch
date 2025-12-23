defmodule BikeBrigadeWeb.CampaignLiveTest do
  use BikeBrigadeWeb.ConnCase, only: []

  import Phoenix.LiveViewTest
  alias BikeBrigadeWeb.CampaignHelpers

  alias BikeBrigade.{Delivery, LocalizedDateTime, History}

  describe "Index" do
    setup [:create_campaign, :login]

    test "lists campaigns for week campaigns", %{conn: conn, program: program} do
      {:ok, _index_live, html} = live(conn, ~p"/campaigns/")

      assert html =~ "Campaigns"
      assert html =~ program.name
    end

    test "redirects to show campaign", %{conn: conn, campaign: campaign, program: program} do
      {:ok, view, _html} = live(conn, ~p"/campaigns/")

      view
      |> element("#campaign-#{campaign.id} a", "#{program.name}")
      |> render_click()

      assert_redirected(view, "/campaigns/#{campaign.id}")
    end

    test "clicking 'New Campaign' goes to new campaign route", ctx do
      {:ok, view, _html} = live(ctx.conn, ~p"/campaigns/")
      view |> element("a", "New Campaign") |> render_click()
      assert_patched(view, ~p"/campaigns/new")
    end

    test "Can duplicate a campaign", ctx do
      # get current week for the query param.
      d = LocalizedDateTime.today() |> Date.beginning_of_week()
      week_str = Date.to_iso8601(d)

      {:ok, view, _html} = live(ctx.conn, ~p"/campaigns/")
      view |> element("#duplicate-campaign-#{ctx.campaign.id}") |> render_click()
      assert_patched(view, ~p"/campaigns/#{ctx.campaign}/duplicate")
      view |> element("#duplicate-campaign-form") |> render_submit()
      assert_redirected(view, ~p"/campaigns?current_week=#{week_str}")

      # Revisit with a fresh view and ensure we have duplicates
      {:ok, view, _html} = live(ctx.conn, ~p"/campaigns/")
      rendered = render(view)

      campaign_rows =
        Floki.parse_fragment!(rendered)
        |> Floki.find("[data-test-group=campaign-name]")
        |> Enum.map(fn x -> String.trim(Floki.text(x)) end)

      assert(Enum.uniq(campaign_rows) != campaign_rows)
    end

    test "Can delete a campaign", ctx do
      {:ok, view, html} = live(ctx.conn, ~p"/campaigns/")
      assert html =~ CampaignHelpers.name(ctx.campaign)
      html = view |> element("#campaign-#{ctx.campaign.id} a", "Delete") |> render_click()
      refute html =~ CampaignHelpers.name(ctx.campaign)
    end
  end

  describe "Show" do
    setup [:create_campaign, :create_rider, :login]

    test "displays campaign", %{conn: conn, campaign: campaign} do
      {:ok, _show_live, html} = live(conn, ~p"/campaigns/#{campaign}")

      assert html =~ campaign.program.name
    end

    @default_location %{
      address: "1 Front Street West",
      coords:
        %Geo.Point{
          coordinates: {-79.37761739999999, 43.6459904},
          srid: nil,
          properties: %{}
        }
        |> Geo.JSON.encode!()
        |> Jason.encode!(),
      postal: "M5J 2X5"
    }

    test "can add a task", %{conn: conn, campaign: campaign} do
      {:ok, view, html} = live(conn, ~p"/campaigns/#{campaign}")

      refute html =~ "Recipient Mcgee"

      view
      |> element("a", "Add Task")
      |> render_click()

      {:ok, _view, html} =
        view
        |> form("#task_form",
          task: %{dropoff_name: "Recipient Mcgee"}
        )
        |> render_submit(%{task: %{dropoff_location: @default_location}})
        # TODO: we should be patching here
        |> follow_redirect(conn)

      assert html =~ "Recipient Mcgee"
    end

    test "can add a rider", %{conn: conn, campaign: campaign, rider: rider} do
      {:ok, view, html} = live(conn, ~p"/campaigns/#{campaign}")

      refute html =~ rider.name

      # Click on add rider
      view
      |> element("a", "Add Rider")
      |> render_click()

      # Select rider
      view
      |> select_rider(rider)

      # Make sure we actually selected the rider
      assert has_element?(
               view,
               ~s|#campaign_rider_form_rider_id input[name="campaign_rider[rider_id]"][value="#{rider.id}"]|
             )

      {:ok, _view, html} =
        view
        |> form("#campaign_rider_form")
        |> render_submit()
        |> follow_redirect(conn)

      assert html =~ rider.name
    end

    test "Can edit campaign rider", %{conn: conn, campaign: campaign, rider: rider} do
      {:ok, view, _html} = live(conn, ~p"/campaigns/#{campaign}")

      starting_form_data = %{
        "enter_building" => "false",
        "pickup_window" => "1-10",
        "rider_capacity" => "15",
        "rider_id" => rider.id
      }

      edit_form_data = %{
        "enter_building" => "true",
        "pickup_window" => "1-11",
        "rider_capacity" => "113",
        "rider_id" => rider.id
      }

      # First add a rider with the starting form data.
      view |> element("a", "Add Rider") |> render_click()
      view |> select_rider(rider)
      view |> submit_campaign_rider_form(starting_form_data, conn)

      # reload view -> check form values for capacity show up
      {:ok, view, html} = live(conn, ~p"/campaigns/#{campaign}")
      assert html =~ "0 / 15"

      # click rider -> Edit Rider -> fill in Form with updated values.
      view |> element("a", rider.name) |> render_click()
      view |> element("a", "Edit Rider") |> render_click()
      view |> submit_campaign_rider_form(edit_form_data, conn)

      # open edit form directly and see that the value prepopulate the form.
      {:ok, view, _html} = live(conn, ~p"/campaigns/#{campaign}/edit_rider/#{rider}")
      assert has_element?(view, ~s|[data-test-rider-capacity="113"]|)
      assert has_element?(view, ~s|[data-test-rider-window="1-11"]|)
    end

    test "'Rider Messaging' button is not visible without riders.", %{
      conn: conn,
      campaign: campaign
    } do
      {:ok, view, _html} = live(conn, ~p"/campaigns/#{campaign}")
      refute view |> element("a", "Rider Messaging") |> has_element?()
    end
  end

  describe "Show with riders" do
    setup [:create_campaign_with_riders, :login]

    test "'Rider Messaging' button is visible when campaign has riders", %{
      conn: conn,
      campaign: campaign
    } do
      {:ok, view, _html} = live(conn, ~p"/campaigns/#{campaign}")
      assert view |> element("a", "Rider Messaging") |> has_element?()
    end

    test "Can assign a rider to a task", ctx do
      rider = hd(ctx.riders)
      task = fixture(:task, %{campaign: ctx.campaign})
      {:ok, view, _html} = live(ctx.conn, ~p"/campaigns/#{ctx.campaign}")

      html =
        view |> element("[id='tasks-list:#{task.id}'] a", task.dropoff_name) |> render_click()

      assert html =~ "Unassigned"

      html = view |> element("a", rider.name) |> render_click()
      assert html =~ "No tasks"

      # assign the task
      view
      |> element("[id='tasks-list:#{task.id}'] a", "Assign to #{rider.name}")
      |> render_click()

      # Note we have to render the view for background database tasks to complete
      assert view |> element("[id='tasks-list:#{task.id}'] a", task.dropoff_name) |> render =~
               "Assigned"

      task = Delivery.get_task(task.id)
      assert task.assigned_rider_id == rider.id

      # Make sure we have a log
      assert [log] = History.list_task_assignment_logs()
      assert log.action == :assigned
      assert log.task_id == task.id
      assert log.rider_id == rider.id
      assert log.user_id == ctx.user.id
    end

    test "Can unassign a rider from a task", ctx do
      rider = hd(ctx.riders)
      task = fixture(:task, %{campaign: ctx.campaign, assigned_rider_id: rider.id})
      {:ok, view, _html} = live(ctx.conn, ~p"/campaigns/#{ctx.campaign}")

      view |> element("[id='tasks-list:#{task.id}'] a", task.dropoff_name) |> render_click()

      # Note we have to render the view for background database tasks to complete
      assert view |> element("[id='tasks-list:#{task.id}'] a", task.dropoff_name) |> render =~
               "Assigned"

      # unassign the task
      view |> element("[id='tasks-list:#{task.id}'] a", "Unassign") |> render_click()

      # Note we have to render the view for background database tasks to complete
      refute view |> element("[id='tasks-list:#{task.id}'] a", task.dropoff_name) |> render =~
               "Assigned"

      task = Delivery.get_task(task.id)
      assert task.assigned_rider_id == nil

      # Make sure we have a log
      assert [log] = History.list_task_assignment_logs()
      assert log.action == :unassigned
      assert log.task_id == task.id
      assert log.rider_id == rider.id
      assert log.user_id == ctx.user.id
    end
  end

  describe "Show with backup riders" do
    setup [:create_campaign, :login]

    test "displays backup riders section when backup riders exist", ctx do
      rider = fixture(:rider)

      # Create a backup rider
      {:ok, _backup_cr} =
        Delivery.create_backup_campaign_rider(%{
          "campaign_id" => ctx.campaign.id,
          "rider_id" => rider.id,
          "rider_capacity" => "5",
          "pickup_window" => "10:00-11:00AM",
          "enter_building" => true,
          "rider_signed_up" => true
        })

      {:ok, _view, html} = live(ctx.conn, ~p"/campaigns/#{ctx.campaign}")

      # Check backup riders section is present
      assert html =~ "Backup Riders (1)"
      assert html =~ rider.name
      assert html =~ "(backup)"
    end

    test "can select a backup rider", ctx do
      rider = fixture(:rider)

      # Create a backup rider
      {:ok, _backup_cr} =
        Delivery.create_backup_campaign_rider(%{
          "campaign_id" => ctx.campaign.id,
          "rider_id" => rider.id,
          "rider_capacity" => "5",
          "pickup_window" => "10:00-11:00AM",
          "enter_building" => true,
          "rider_signed_up" => true
        })

      {:ok, view, _html} = live(ctx.conn, ~p"/campaigns/#{ctx.campaign}")

      view |> element("#backup-riders-list a", rider.name) |> render_click()
      assert view |> element("a", "Convert to Rider") |> has_element?()
    end

    test "can convert backup rider to regular rider", ctx do
      rider = fixture(:rider)

      # Create a backup rider
      {:ok, _backup_cr} =
        Delivery.create_backup_campaign_rider(%{
          "campaign_id" => ctx.campaign.id,
          "rider_id" => rider.id,
          "rider_capacity" => "5",
          "pickup_window" => "10:00-11:00AM",
          "enter_building" => true,
          "rider_signed_up" => true
        })

      {:ok, view, _html} = live(ctx.conn, ~p"/campaigns/#{ctx.campaign}")

      # First click on backup rider to select them
      updated_html = view |> element("#backup-riders-list a", rider.name) |> render_click()

      # check that backup rider details are showing
      assert updated_html =~ "Convert to Rider"

      # Now convert should be available
      view |> element("a", "Convert to Rider") |> render_click()
      # after converting to a rider, confirm the button no longer exists.
      refute view |> element("a", "Convert to Rider") |> has_element?
    end

    test "can remove backup rider", ctx do
      rider = fixture(:rider)

      # Create a backup rider
      {:ok, _backup_cr} =
        Delivery.create_backup_campaign_rider(%{
          "campaign_id" => ctx.campaign.id,
          "rider_id" => rider.id,
          "rider_capacity" => "5",
          "pickup_window" => "10:00-11:00AM",
          "enter_building" => true,
          "rider_signed_up" => true
        })

      {:ok, view, _html} = live(ctx.conn, ~p"/campaigns/#{ctx.campaign}")

      # First click on backup rider to select them
      view |> element("#backup-riders-list a", rider.name) |> render_click()

      # Now remove should be available
      view |> element("a", "Remove Backup") |> render_click()

      # Backup rider should no longer exist
      # refute render(view) =~ "Backup Riders"
      refute render(view) =~ rider.name
    end

    test "cannot assign tasks to backup riders", ctx do
      rider = fixture(:rider)
      task = fixture(:task, %{campaign: ctx.campaign})

      # Create a backup rider
      {:ok, _backup_cr} =
        Delivery.create_backup_campaign_rider(%{
          "campaign_id" => ctx.campaign.id,
          "rider_id" => rider.id,
          "rider_capacity" => "5",
          "pickup_window" => "10:00-11:00AM",
          "enter_building" => true,
          "rider_signed_up" => true
        })

      {:ok, view, _html} = live(ctx.conn, ~p"/campaigns/#{ctx.campaign}")

      # Select the task first
      view |> element("[id='tasks-list:#{task.id}'] a", task.dropoff_name) |> render_click()

      # Select the backup rider
      view |> element("#backup-riders-list a", rider.name) |> render_click()

      # Should show message that backup rider cannot be assigned tasks
      task_html = view |> element("[id='tasks-list:#{task.id}']") |> render()
      assert task_html =~ "#{rider.name} is a backup rider - cannot assign tasks"
      refute task_html =~ "Assign to #{rider.name}"
    end

    test "can message backup riders", ctx do
      rider = fixture(:rider)

      # Create a backup rider
      {:ok, _backup_cr} =
        Delivery.create_backup_campaign_rider(%{
          "campaign_id" => ctx.campaign.id,
          "rider_id" => rider.id,
          "rider_capacity" => "5",
          "pickup_window" => "10:00-11:00AM",
          "enter_building" => true,
          "rider_signed_up" => true
        })

      {:ok, view, _html} = live(ctx.conn, ~p"/campaigns/#{ctx.campaign}")

      # Click on backup rider
      view |> element("#backup-riders-list a", rider.name) |> render_click()

      # Should have message button
      assert has_element?(view, "a[href='/messages/#{rider.id}']", "Message")
    end
  end

  # Still a work in progress
  @tag :skip
  describe "New" do
    setup [:create_campaign, :login]

    test "create campaigns", %{conn: conn} do
      #  Process.flag(:trap_exit, true)
      {:ok, view, html} = live(conn, ~p"/campaigns/new")

      assert html =~ "New Campaign"

      deliveries =
        file_input(view, "form", :delivery_spreadsheet, [
          %{
            name: "deliveries.csv",
            content: """
            Visit Name,Street,Zip code,Phone,Notes,Buzzer and Unit,Partner,Box Type
            Mark C,1899 Queen St West,M6R 1A9,16475551922,Deliver to security; security will drop-off,123,ABC,Large box
            Sofia Q,924 College St,M6H 1A4,4165551234,,Buzz: 20 Unit 32,Large box
            """,
            type: "text/csv"
          }
        ])

      # Process.unlink(deliveries.pid)
      render_upload(deliveries, "deliveries.csv", 100)
      {_, _, proxy_pid} = view.proxy

      assert_receive {:EXIT, ^proxy_pid, {:shutdown, :closed}}

      deliveries =
        file_input(view, "form", :delivery_spreadsheet2, [
          %{
            name: "deliveries.csv",
            content: """
            Visit Name,Street,Zip code,Phone,Notes,Buzzer and Unit,Partner,Box Type
            Mark C,1899 Queen St West,M6R 1A9,16475551922,Deliver to security; security will drop-off,123,ABC,Large box
            Sofia Q,924 College St,M6H 1A4,4165551234,,Buzz: 20 Unit 32,Large box
            """,
            type: "text/csv"
          }
        ])

      render_upload(deliveries, "deliveries.csv", 100)
      {_, _, proxy_pid} = view.proxy

      assert_receive {:EXIT, ^proxy_pid, {:shutdown, :closed}}
    end
  end

  # Select a rider from the rider selection component
  defp select_rider(view, rider) do
    # Find a rider
    view
    |> element("#campaign_rider_form_rider_id input")
    |> render_keyup(%{value: rider.name})

    view
    |> element("#campaign_rider_form_rider_id a")
    |> render_click()

    view
  end

  defp submit_campaign_rider_form(view, form_vals, conn) do
    view
    |> form("#campaign_rider_form", campaign_rider: form_vals)
    |> render_submit()
    |> follow_redirect(conn)
  end
end
