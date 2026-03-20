# Repo
alias BikeBrigade.Repo

# Main Contexts
alias BikeBrigade.{
  Delivery,
  Riders,
  Accounts,
  Messaging,
  Locations,
  History,
  Notifications,
  Stats,
  SlackApi
}

# Delivery Schemas
alias BikeBrigade.Delivery.{
  Campaign,
  CampaignRider,
  Task,
  TaskItem,
  Program,
  Item,
  Opportunity,
  DeliveryNote
}

# Rider Schemas
alias BikeBrigade.Riders.{
  Rider,
  Tag,
  RiderSearch
}

# Account / User
alias BikeBrigade.Accounts.User

# Location Schemas
alias BikeBrigade.Locations.{Location, Neighborhood}

# Messaging Schemas
alias BikeBrigade.Messaging.{SmsMessage, ScheduledMessage, Template}

# Other Schemas
alias BikeBrigade.History.TaskAssignmentLog
alias BikeBrigade.Notifications.Banner
alias BikeBrigade.Stats.{RiderStats, CampaignStats}

# Utilities
alias BikeBrigade.{Utils, LocalizedDateTime, SmsService}

# Ecto helpers
import Ecto.Query
