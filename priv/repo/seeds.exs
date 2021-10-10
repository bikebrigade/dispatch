alias BikeBrigade.Repo
alias BikeBrigade.Delivery.Campaign
alias BikeBrigade.Riders.Rider
alias BikeBrigade.Utils
alias BikeBrigade.Repo.Seeds.Toronto

alias BikeBrigade.LocalizedDateTime

# Create a dispatcher

{:ok, _} =
  BikeBrigade.Accounts.create_user(%{
    name: "Dispatcher McGee",
    phone: "647-555-5555",
    email: "dispatcher@example.com"
  })

# Create some riders

for _ <- 0..100 do
  address = Toronto.random_address()

  {:ok, _rider} =
    BikeBrigade.Riders.create_rider(%{
      address: address[:address],
      # TODO
      availability: %{},
      capacity: Utils.random_enum(Rider.CapacityEnum),
      city: address[:city],
      country: address[:country],
      email: Faker.Internet.email(),
      location: %Geo.Point{coordinates: {address[:lng], address[:lat]}},
      max_distance: 20,
      name: "#{Faker.Person.first_name()} #{Faker.Person.last_name()}",
      phone: "647-#{Enum.random(200..999)}-#{Enum.random(1000..9999)}",
      postal: address[:postal],
      pronouns: Enum.random(~w(He/Him She/Her They/Them)),
      province: address[:province],
      signed_up_on: LocalizedDateTime.now()
    })
end
