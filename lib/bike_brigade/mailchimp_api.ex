defmodule BikeBrigade.MailchimpApi do
  use BikeBrigade.Adapter, :mailchimp

  @type list_id :: String.t()
  @type opted_in :: String.t() | nil
  @type members :: list(map())

  @callback get_list(list_id, opted_in) :: {:ok, members} | {:error, any()}

  @doc """
  Get mailing list's members
  """
  def get_list(list_id, opted_in \\ nil), do: @mailchimp.get_list(list_id, opted_in)
end
