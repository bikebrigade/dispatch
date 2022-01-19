defmodule BikeBrigade.Importers.MailchimpImporterTest do
  use BikeBrigade.DataCase

  alias BikeBrigade.Importers.MailchimpImporter

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
  test "parse_mailchimp_attrs is successful if fields from Mailchimp are valid" do
    {:ok, expected_fields} = MailchimpImporter.parse_mailchimp_attrs(@valid_attrs)
    address = expected_fields[:location_struct][:address]
    assert address == "1508 Davenport Rd Toronto"
  end

  test "parse_mailchimp_attrs returns an error if the phone number is not a valid Canadian number" do
    invalid_attrs = put_in(@valid_attrs, [:merge_fields, :PHONEYUI_], "oops")
    {:error, _} = MailchimpImporter.parse_mailchimp_attrs(invalid_attrs)
  end

  test "parse_mailchimp_attrs returns an error if address fails geocoding" do
    invalid_attrs = put_in(@valid_attrs, [:merge_fields, :TEXTYUI_3], "oops")

    {:error, {:update_location, _}} = MailchimpImporter.parse_mailchimp_attrs(invalid_attrs)
  end

  test "sync_riders is successful when all required attributes are valid" do
    {:ok, _} = MailchimpImporter.sync_riders({:ok, [@valid_attrs]})
  end

  test "sync_riders handles case where phone is invalid" do
    invalid_attrs = put_in(@valid_attrs, [:merge_fields, :TEXTYUI_3], "oops")

    {:ok, _} = MailchimpImporter.sync_riders({:ok, [invalid_attrs]})
  end

  test "sync_riders handles case where address is invalid" do
    invalid_attrs = put_in(@valid_attrs, [:merge_fields, :TEXTYUI_3], "oops")

    {:ok, _} = MailchimpImporter.sync_riders({:ok, [invalid_attrs]})
  end
end
