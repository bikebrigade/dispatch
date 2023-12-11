defmodule BikeBrigadeWeb.CampaignSignupLiveTest do
  use BikeBrigadeWeb.ConnCase, only: []

  import Phoenix.LiveViewTest
  # alias BikeBrigadeWeb.CampaignHelpers
  # alias BikeBrigade.LocalizedDateTime


  describe "Index - General" do

    test "It displays the expected number of campaigns for this week" do

    end

    test "It displays a capaign in a future week" do

    end

    test "It displays a capaign in a previous week" do

    end
  end

  describe "Index - Campaign shows correct signup button" do

    test "A campaign shows the correct filled to total tasks" do
      assert 1 == 2
    end

    test "'signup' when rider hasn't signed up and there are open tasks" do

    end

    test "'signed up for N deliveries' if open deliveries and rider has at least one. " do

    end

    test "'completed' and cannot be clicked when a campaign is in the past" do

    end
  end


  describe "Show" do
    test "Signup flow works" do

    end

    test "Invalid route for task shows flash" do

    end

    test "Ride can unassign themselves" do

    end
  end

end
