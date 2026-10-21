# Seeds campaigns, delivery assignments, and conversations for exploring the
# messaging inbox and its deliveries panel.
#
#     mix run priv/repo/seeds/messaging_inbox.exs
#
# Safe to run more than once; each run adds a fresh set of campaigns. Requires the
# base seeds (`mix run priv/repo/seeds.exs`) for riders and the dispatcher.

alias BikeBrigade.{Accounts, Delivery, LocalizedDateTime, Messaging, Repo, Riders}
alias BikeBrigade.Repo.Seeds.{Seeder, Toronto}

dispatcher =
  Repo.get_by(Accounts.User, email: "dispatcher@example.com") ||
    raise "Run priv/repo/seeds.exs first to create dispatcher@example.com"

{:ok, dispatcher} =
  Accounts.update_user_as_admin(dispatcher, %{flags: %{unified_messaging: true}})

riders = Riders.list_riders() |> Enum.filter(& &1.phone) |> Enum.shuffle()
if length(riders) < 30, do: raise("Run priv/repo/seeds.exs first to create riders")

program =
  Seeder.program()
  |> Delivery.Program.changeset(%{lead_id: dispatcher.id})
  |> Repo.update!()

for _ <- 1..3, do: Seeder.item_for_program(program)

today = LocalizedDateTime.today()

# {label, day, start time, number of riders, statuses to cycle through}
campaigns = [
  {"yesterday", Date.add(today, -1), ~T[14:00:00], 4, [:completed, :completed, :pending]},
  {"this morning", today, ~T[10:00:00], 5, [:completed, :pending]},
  {"this afternoon", today, ~T[15:00:00], 5, [:pending]},
  # Outside the deliveries window, so its riders shouldn't get the deliveries bar or panel.
  {"in three days", Date.add(today, 3), ~T[12:00:00], 3, [:pending]}
]

incoming = [
  "On my way to pickup now",
  "Nobody's answering at the door, what should I do?",
  "Done with my first drop!",
  "Is the second address the side entrance?",
  "Running about 10 minutes late, sorry",
  "All delivered 👍"
]

outgoing = [
  "Thanks for riding today!",
  "Try calling the recipient, number is in your app",
  "Leave it with the concierge if they don't answer",
  "No worries, thanks for the heads up"
]

{campaign_riders, _} =
  Enum.map_reduce(campaigns, riders, fn {label, day, time, rider_count, statuses}, riders ->
    {campaign_riders, riders} = Enum.split(riders, rider_count)
    start = LocalizedDateTime.new!(day, time)

    {:ok, campaign} =
      Delivery.create_campaign(%{
        program_id: program.id,
        delivery_start: start,
        delivery_end: DateTime.add(start, 3, :hour),
        location: Toronto.random_location()
      })

    for {rider, i} <- Enum.with_index(campaign_riders) do
      {:ok, _} =
        Delivery.create_campaign_rider(%{
          campaign_id: campaign.id,
          rider_id: rider.id,
          rider_capacity: 3,
          pickup_window:
            "#{Calendar.strftime(time, "%-I:%M")}–#{Calendar.strftime(Time.add(time, 30, :minute), "%-I:%M %p")}"
        })

      # 1–3 deliveries per rider, with statuses cycling so each campaign has a mix.
      for j <- 0..rem(i, 3) do
        task = Seeder.task_for_campaign(campaign)
        {:ok, task} = Delivery.assign_task(task, rider.id, dispatcher.id)

        {:ok, _} =
          Delivery.update_task(task, %{
            dropoff_phone: "416-555-#{Enum.random(1000..9999)}",
            delivery_instructions:
              Enum.random(["Buzz 204", "Side door", "Leave with concierge", nil]),
            delivery_status: Enum.at(statuses, rem(i + j, length(statuses)))
          })
      end
    end

    IO.puts("Created campaign #{campaign.id} (#{label}) with #{rider_count} riders")
    {Enum.map(campaign_riders, &{&1, start}), riders}
  end)

# Give every campaign rider a short conversation so they show up in the inbox.
for {{rider, start}, i} <- Enum.with_index(List.flatten(campaign_riders)) do
  rider_number = Messaging.inbound_number(rider)

  [
    {false, Enum.at(outgoing, rem(i, length(outgoing))), -60},
    {true, Enum.at(incoming, rem(i, length(incoming))), 15}
  ]
  |> Enum.each(fn {incoming?, body, minutes} ->
    {from, to} = if incoming?, do: {rider.phone, rider_number}, else: {rider_number, rider.phone}

    {:ok, _} =
      Messaging.create_sms_message(%{
        rider_id: rider.id,
        incoming: incoming?,
        from: from,
        to: to,
        body: body,
        sent_at: DateTime.add(start, minutes, :minute),
        sent_by_user_id: unless(incoming?, do: dispatcher.id)
      })
  end)
end

IO.puts("""

Program "#{program.name}" is led by #{dispatcher.email}, who is now opted into the
unified messaging inbox. Open /messages/inbox?tab=campaigns to explore.
""")
