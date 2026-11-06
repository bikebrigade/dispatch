defmodule BikeBrigade.Selfies do
  @moduledoc "Uploads rider selfies to the same Drive folder used by incoming SMS media."

  alias BikeBrigade.Google.Drive
  alias BikeBrigade.LocalizedDateTime

  @folder "12avCsCaaNEtxcqvdUiijSQhWGyRBjC0B"

  def folder, do: @folder

  def upload(path, content_type, rider, campaign) do
    date = LocalizedDateTime.to_date(campaign.delivery_start)

    Drive.upload_file(path, @folder,
      name: "#{date} - #{rider.name} - #{campaign.program.name}",
      content_type: content_type
    )
  end
end
