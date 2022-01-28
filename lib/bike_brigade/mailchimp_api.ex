defmodule BikeBrigade.MailchimpApi do
  use BikeBrigade.Adapter, :mailchimp

  @type list_id :: String.t()
  @type last_changed :: String.t() | nil
  @type members :: list(map())

  @callback get_list(list_id, last_changed) :: {:ok, members} | {:error, any()}

  @doc """
  Get mailing list's members
  """
  def get_list(list_id, last_changed \\ nil), do: @mailchimp.get_list(list_id, last_changed)
end
