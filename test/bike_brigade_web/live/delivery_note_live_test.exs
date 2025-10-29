defmodule BikeBrigadeWeb.DeliveryNoteLiveTest do
  use BikeBrigadeWeb.ConnCase
  import Phoenix.LiveViewTest

  alias BikeBrigade.Delivery

  setup [:login]

  describe "DeliveryNotes :index" do
    test "displays delivery notes", ctx do
      # Create test data
      rider = fixture(:rider)
      task = fixture(:task)

      {:ok, _delivery_note} =
        Delivery.create_delivery_note(%{
          note: "Test delivery note",
          rider_id: rider.id,
          task_id: task.id
        })

      # Visit the delivery notes page
      {:ok, _view, html} = live(ctx.conn, ~p"/delivery_notes")

      # Assert that the note is displayed
      assert html =~ "Test delivery note"
      assert html =~ rider.name
    end

    test "displays empty state when no notes exist", ctx do
      {:ok, _view, html} = live(ctx.conn, ~p"/delivery_notes")

      assert html =~ "No unresolved delivery notes."
      assert html =~ "No resolved delivery notes."
    end

    test "can mark a note as resolved", ctx do
      # Create test data
      rider = fixture(:rider)
      task = fixture(:task)

      {:ok, _delivery_note} =
        Delivery.create_delivery_note(%{
          note: "Test delivery note",
          rider_id: rider.id,
          task_id: task.id
        })

      # Visit the delivery notes page
      {:ok, view, html} = live(ctx.conn, ~p"/delivery_notes")

      # Verify initial state - note shows as unresolved
      assert html =~ "Unresolved"
      refute html =~ ~r/class="[^"]*bg-green-100[^"]*">/

      # Click resolve button
      html = view |> element("button", "Mark as Resolved") |> render_click()

      # Verify note is now resolved
      assert html =~ "Resolved"
      assert html =~ ctx.user.name
    end

    test "can mark a note as unresolved", ctx do
      # Create test data
      rider = fixture(:rider)
      task = fixture(:task)

      {:ok, delivery_note} =
        Delivery.create_delivery_note(%{
          note: "Test delivery note",
          rider_id: rider.id,
          task_id: task.id
        })

      # Resolve the note
      {:ok, _resolved_note} = Delivery.resolve_delivery_note(delivery_note, ctx.user.id)

      # Visit the delivery notes page
      {:ok, view, html} = live(ctx.conn, ~p"/delivery_notes")

      # Verify initial state
      assert html =~ "Resolved"

      # Click unresolve button
      html = view |> element("button", "Mark as Unresolved") |> render_click()

      # Verify note is now unresolved
      assert html =~ "Unresolved"
      refute html =~ "by #{ctx.user.name}"
    end

    test "shows who resolved the note", ctx do
      # Create test data
      rider = fixture(:rider)
      task = fixture(:task)

      {:ok, delivery_note} =
        Delivery.create_delivery_note(%{
          note: "Test delivery note",
          rider_id: rider.id,
          task_id: task.id
        })

      # Resolve the note
      {:ok, _delivery_note} = Delivery.resolve_delivery_note(delivery_note, ctx.user.id)

      # Visit the delivery notes page
      {:ok, _view, html} = live(ctx.conn, ~p"/delivery_notes")

      # Verify the resolver is displayed
      assert html =~ "by #{ctx.user.name}"
    end
  end
end
