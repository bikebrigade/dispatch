defmodule BikeBrigade.MailchimpApi.Http do
  alias BikeBrigade.MailchimpApi

  @behaviour MailchimpApi

  @count 100

  @impl MailchimpApi
  def get_list(list_id, last_changed \\ nil) do
    with {:ok, account} <- Mailchimp.Account.get(),
         {:ok, list} <- Mailchimp.Account.get_list(account, list_id) do
      # Infinite sequence of offsets 0,100,200,...
      offsets = Stream.iterate(0, &(&1 + @count))

      {members, status} =
        Enum.flat_map_reduce(offsets, :ok, fn offset, _status ->
          case Mailchimp.List.members(list, %{
                 count: @count,
                 offset: offset,
                 fields:
                   "members.email_address,members.id,members.status,members.merge_fields,members.timestamp_opt",
                 since_last_changed: last_changed
               }) do
            {:ok, []} -> {:halt, :ok}
            {:ok, members} -> {members, :ok}
            {:error, err} -> {:error, err}
          end
        end)

      {status, members}
    end
  end
end
