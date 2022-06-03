alias BikeBrigade.{
  Accounts,
  Delivery,
  LocalizedDateTime,
  Riders,
  Utils
}

alias BikeBrigade.Repo.Seeds.{Seeder, Toronto}

# Create a dispatcher
if Accounts.list_users() == [] do
  Accounts.create_user(%{
    name: "Dispatcher McGee",
    phone: "647-555-5555",
    email: "dispatcher@example.com"
  })
end

# Create some riders
if Riders.list_riders() == [] do
  for _ <- 0..100 do
    location = Toronto.random_location()

    {:ok, _rider} =
      Riders.create_rider(%{
        address: location.address,
        # TODO
        capacity: Utils.random_enum(Riders.Rider.CapacityEnum),
        email: Faker.Internet.email(),
        location: location,
        max_distance: 20,
        name: "#{Faker.Person.first_name()} #{Faker.Person.last_name()}",
        phone: "647-#{Enum.random(200..999)}-#{Enum.random(1000..9999)}",
        postal: location.postal,
        pronouns: Enum.random(~w(He/Him She/Her They/Them)),
        signed_up_on: LocalizedDateTime.now()
      })
  end
end

# Seed 2 programs
if Delivery.list_programs() == [] do
  for _ <- 1..2 do
    Seeder.program()
  end
end

for program <- Delivery.list_programs() do
  if Delivery.list_items(program.id) == [] do
    # Seed 3 items/program
    for _ <- 1..3 do
      Seeder.item_for_program(program)
    end
  end

  if Delivery.list_campaigns()
     |> Enum.filter(fn campaign -> campaign.program_id == program.id end) == [] do
    # Seed 1 campaign/program
    campaign = Seeder.campaign_for_program(program)

    # Seed 3 tasks/campaign
    for _ <- 1..3 do
      Seeder.rider_for_campaign(campaign)
    end

    # Seed 5 riders/campaign
    for _ <- 1..5 do
      Seeder.task_for_campaign(campaign)
    end
  end
end
