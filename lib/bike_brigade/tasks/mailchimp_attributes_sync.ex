defmodule BikeBrigade.Tasks.MailchimpAttributesSync do
  import Ecto.Query, warn: false
  import BikeBrigade.Utils, only: [get_config: 1]
  alias BikeBrigade.Repo
  alias BikeBrigade.Tasks.Importer
  alias BikeBrigade.Riders.Rider

  alias BikeBrigade.MailchimpApi

  @task_name "mailchimp_attributes_sync"

  # Lets us update values in maps stored as jsonb without losing keys we dont care about
  @update_data_map from(i in Importer,
                     update: [set: [data: fragment("? || excluded.data", i.data)]]
                   )

  def sync_mailchimp_attributes() do
    Repo.transaction(
      fn ->
        last_synced =
          Repo.one(
            from i in Importer,
              where: i.name == ^@task_name,
              lock: "FOR UPDATE SKIP LOCKED",
              select: fragment("? ->> 'last_synced'", i.data)
          )

        list_id = get_config(:list_id)

        query =
          from r in Rider,
            join: c in assoc(r, :latest_campaign),
            as: :latest_campaign,
            preload: [:latest_campaign, :total_stats]

        query =
          if last_synced do
            query
            |> where([latest_campaign: c], c.delivery_start > ^last_synced)
          else
            query
          end

        riders = Repo.all(query)

        for rider <- riders do
          task_count =  if rider.total_stats, do:  rider.total_stats.task_count, else: 0
          MailchimpApi.update_member_fields(list_id, rider.email, %{
            LAST_RIDE: rider.latest_campaign.delivery_start,
            TASK_COUNT: task_count
          })
        end

        Repo.insert(%Importer{name: @task_name, data: %{last_synced: DateTime.utc_now()}},
          returning: true,
          on_conflict: @update_data_map,
          conflict_target: :name
        )
      end,
      timeout: :infinity
    )
  end
end
