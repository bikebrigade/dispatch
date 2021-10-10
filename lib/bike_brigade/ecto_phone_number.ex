defmodule BikeBrigade.EctoPhoneNumber do
  @moduledoc """
  Custom phone number type. I had some issues with https://github.com/surgeventures/ecto-phone-number and Canadian numbers.
  This is uses the ex_phone_number library but I simplified a lot based on my usecase
  """
  defmodule InvalidNumber do
    defexception message: "invalid phone number"
  end

  defmodule Canadian do
    use Ecto.Type
    def type, do: :map

    @region_code "CA"

    def cast(phone_number) when is_binary(phone_number) do
      case ExPhoneNumber.parse(phone_number, @region_code) do
        {:ok, phone_number} ->
          cast(phone_number)

        {:error, err} ->
          {:error, message: err}
      end
    end

    def cast(%ExPhoneNumber.Model.PhoneNumber{} = phone_number) do
      if ExPhoneNumber.is_valid_number?(phone_number) do
        {:ok, ExPhoneNumber.format(phone_number, :e164)}
      else
        {:error, message: "phone number is not valid for Canada"}
      end
    end

    def load(data) when is_binary(data), do: {:ok, data}
    def dump(data) when is_binary(data), do: {:ok, data}
  end
end
