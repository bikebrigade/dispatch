alias BikeBrigade.{Accounts, Delivery, Riders}
alias BikeBrigade.Repo.Seeds.Seeder

# Create a dispatcher
if Accounts.list_users() == [] do
  Seeder.user()
end

# Create some riders
if Riders.list_riders() == [] do
  for _ <- 0..100 do
    Seeder.rider()
  end
end

# Seed 2 programs
if Delivery.list_programs() == [] do
  for _ <- 1..2 do
    program = Seeder.program()
    # Seed 3 items/program
    for _ <- 1..3 do
      Seeder.item_for_program(program)
    end
  end
end

for program <- Delivery.list_programs() do
  if Delivery.list_campaigns()
     |> Enum.filter(fn campaign -> campaign.program_id == program.id end) == [] do
    # Seed 1 campaign/program
    campaign = Seeder.campaign_for_program(program)

    # Seed 3 riders/campaign
    for _ <- 1..3 do
      Seeder.rider_for_campaign(campaign)
    end

    # Seed 5 tasks/campaign
    for _ <- 1..5 do
      Seeder.task_for_campaign(campaign)
    end
  end
end
