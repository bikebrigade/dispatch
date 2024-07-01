defmodule BikeBrigade.MailchimpApi do
  use BikeBrigade.Adapter, :mailchimp

  @type list_id :: String.t()
  @type opted_in :: String.t() | nil
  @type email :: String.t()
  @type members :: list(map())
  @type fields :: map()

  @callback get_list(list_id, opted_in) :: {:ok, members} | {:error, any()}
  @callback update_member_fields(list_id, email, fields) :: {:ok, members} | {:error, any()}

  @doc """
  Get mailing list's members
  """
  def get_list(list_id, opted_in \\ nil), do: adapter().get_list(list_id, opted_in)

  @doc """
  Update merge fields for a member
  """
  def update_member_fields(list_id, email, fields),
    do: adapter().update_member_fields(list_id, email, fields)
end
