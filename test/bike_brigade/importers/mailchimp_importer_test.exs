defmodule BikeBrigade.Importers.MailchimpImporterTest do
  use BikeBrigade.DataCase

  alias BikeBrigade.Importers.MailchimpImporter

  @valid_attrs %{
    id: "123",
    email_address: "dispatcher@example.com",
    "status": "subscribed",
    "timestamp_opt": "2019-08-24T14:15:22Z",
    merge_fields: %{
      PHONEYUI_: "647-555-5555",
      PHONE: "647-555-5555",
      TEXTYUI_3: "1508 Davenport Rd"
    }
  }
  test "build_rider is successful if fields from Mailchimp are valid" do
    {:ok, expected_fields} = MailchimpImporter.build_rider(@valid_attrs)
    address = expected_fields[:location_struct][:address]
    assert address == "1508 Davenport Rd Toronto"
  end

  test "build_rider fails gracefully if address fails geocoding" do
    invalid_attrs = put_in(@valid_attrs, [:merge_fields, :TEXTYUI_3], "oops")

    {:ok, expected_fields} = MailchimpImporter.build_rider(invalid_attrs)
    address = expected_fields[:location_struct][:address]
    assert address == "1 Front St"
  end
end
