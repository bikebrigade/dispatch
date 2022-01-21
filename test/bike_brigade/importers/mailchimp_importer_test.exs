defmodule BikeBrigade.Importers.MailchimpImporterTest do
  use BikeBrigade.DataCase

  alias BikeBrigade.Repo
  alias BikeBrigade.Importers.MailchimpImporter
  alias BikeBrigade.MailchimpApi.FakeMailchimp
  alias BikeBrigade.SlackApi.FakeSlack

  alias BikeBrigade.Riders

  @list_id "LIST_ID"

  @valid_attrs %{
    id: "123",
    email_address: "dispatcher@example.com",
    status: "subscribed",
    timestamp_opt: "2019-08-24T14:15:22Z",
    merge_fields: %{
      FNAME: "Morty",
      PHONEYUI_: "647-555-5555",
      PHONE: "647-555-5555",
      TEXTYUI_3: "1508 Davenport Rd"
    }
  }

  describe "parse_mailchimp_attrs/1" do
    test "is successful if fields from Mailchimp are valid" do
      {:ok, expected_fields} = MailchimpImporter.parse_mailchimp_attrs(@valid_attrs)
      address = expected_fields[:location_struct][:address]
      assert address == "1508 Davenport Rd Toronto"
    end

    test "returns an error if the phone number is not a valid Canadian number" do
      invalid_attrs = put_in(@valid_attrs, [:merge_fields, :PHONEYUI_], "oops")
      {:error, _} = MailchimpImporter.parse_mailchimp_attrs(invalid_attrs)
    end

    test "returns an error if address fails geocoding" do
      invalid_attrs = put_in(@valid_attrs, [:merge_fields, :TEXTYUI_3], "oops")

      {:error, {:update_location, _}} = MailchimpImporter.parse_mailchimp_attrs(invalid_attrs)
    end
  end

  describe "sync_riders/0" do
    setup do
      saved_env = Application.get_env(:bike_brigade, BikeBrigade.Importers.MailchimpImporter)

      Application.put_env(
        :bike_brigade,
        BikeBrigade.Importers.MailchimpImporter,
        Keyword.put(saved_env, :list_id, @list_id)
      )

      on_exit(fn ->
        FakeMailchimp.clear_members(@list_id)

        Application.put_env(:bike_brigade, BikeBrigade.Importers.MailchimpImporter, saved_env)
      end)
    end

    test "is successful when all required attributes are valid" do
      assert Riders.get_rider_by_email("dispatcher@example.com") == nil
      FakeMailchimp.add_members(@list_id, [@valid_attrs])

      assert {:ok, _} = MailchimpImporter.sync_riders()

      r = Riders.get_rider_by_email("dispatcher@example.com")

      assert r.name == "Morty"
      assert r.location_struct.address == "1508 Davenport Rd Toronto"
    end

    test "handles case where phone is invalid" do
      invalid_attrs = put_in(@valid_attrs, [:merge_fields, :PHONEYUI_], "oops")
      FakeMailchimp.add_members(@list_id, [invalid_attrs])

      assert {:ok, _} = MailchimpImporter.sync_riders()

      assert Riders.get_rider_by_email("dispatcher@example.com") == nil

      call = FakeSlack.get_last_call()
      assert call[:body] =~ "An error ocurred when importing dispatcher@example.com"
    end

    test "handles case where address is invalid" do
      invalid_attrs = put_in(@valid_attrs, [:merge_fields, :TEXTYUI_3], "oops")
      FakeMailchimp.add_members(@list_id, [invalid_attrs])

      assert {:ok, _} = MailchimpImporter.sync_riders()

      r = Riders.get_rider_by_email("dispatcher@example.com")

      assert r.name == "Morty"

      # The rider has a default location
      assert r.location_struct.address == "1 Front St"

      # We alert on slack
      call = FakeSlack.get_last_call()
      assert call[:body] =~ "We had trouble with the address for Morty."

      # We tag the rider
      assert [%{name: "invalid_location"}] = Repo.preload(r, :tags).tags
    end
  end
end
