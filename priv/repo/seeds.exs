alias BikeBrigade.Accounts
alias BikeBrigade.Riders
alias BikeBrigade.Utils
alias BikeBrigade.Repo.Seeds.Toronto

alias BikeBrigade.LocalizedDateTime

# Create a dispatcher

if Accounts.list_users() == [] do
  BikeBrigade.Accounts.create_user(%{
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
      BikeBrigade.Riders.create_rider(%{
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
