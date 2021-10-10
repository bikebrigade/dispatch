defmodule BikeBrigade.Delivery.ApiSync do
  @moduledoc """
  Various tools to sync with APIs we use

  So far these are run manually in the console, with the intention to automate some of this stuff via webhooks etc.

  Currently we're integrating with
   - Onfleet
   - Mailchimp
  """
  alias BikeBrigade.Repo
  alias BikeBrigade.Riders
  alias BikeBrigade.Riders.Rider

  import Ecto.Query

  require Logger
  # Hardcoded id of our main list
  @mailchimp_list_id "248c25df52"
  @doc """
  Sync mailchimp id and status for all riders
  """
  def mailchimp_sync do
      Mailchimp.Account.get!()
      |> Mailchimp.Account.get_list!(@mailchimp_list_id)
      |> Mailchimp.List.members!(%{
        fields: "members.email_address,members.id,members.status",
        count: 1000
      })
      |> Enum.each(fn member ->
        r = Repo.one(from r in Rider, where: r.email == ^member.email_address)

        if r do
          Riders.update_rider(r, %{mailchimp_id: member.id, mailchimp_status: member.status})
        end
      end)
  end

  def get_mailchimp_member(email) do
    Mailchimp.Account.get!()
    |> Mailchimp.Account.get_list!(@mailchimp_list_id)
    |> Mailchimp.List.get_member(email)
  end

  @doc """
  onetime use and very foodshare specific leaving this here for future ref
  """
  def foodshare_mailchimp_tag(riders) do
    invited_tag = %{id: 789_558, name: "foodshare_onfleet:invited"}
    accepted_tag = %{id: 789_554, name: "foodshare_onfleet:accepted"}
    experienced_tag = %{id: 789_550, name: "foodshare_onfleet:experienced"}

    {experienced, accepted, invited} =
      riders
      |> Enum.reduce({[], [], []}, fn rider, {experienced, accepted, invited} ->
        cond do
          rider.deliveries_completed > 0 ->
            {[rider.email | experienced], accepted, invited}

          rider.onfleet_account_status == :accepted ->
            {experienced, [rider.email | accepted], invited}

          rider.onfleet_account_status == :invited ->
            {experienced, accepted, [rider.email | invited]}

          true ->
            {experienced, accepted, [rider.email | invited]}
        end
      end)

    list =
      Mailchimp.Account.get!()
      |> Mailchimp.Account.get_list!(@mailchimp_list_id)

    segments_url = list.links["segments"].href

    Mailchimp.HTTPClient.post!(
      "#{segments_url}/#{experienced_tag[:id]}",
      Jason.encode!(%{members_to_add: experienced})
    )

    Mailchimp.HTTPClient.post!(
      "#{segments_url}/#{accepted_tag[:id]}",
      Jason.encode!(%{members_to_add: accepted})
    )

    Mailchimp.HTTPClient.post!(
      "#{segments_url}/#{invited_tag[:id]}",
      Jason.encode!(%{members_to_add: invited})
    )
  end
end
