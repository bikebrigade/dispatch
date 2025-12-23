defmodule BikeBrigade.SlackApi.Http do
  alias BikeBrigade.SlackApi

  @behaviour SlackApi

  def get!(url, headers) do
    response = HTTPoison.get!(url, headers)

    if response.status_code != 200 do
      raise SlackApi.Error, response
    end

    body = Jason.decode!(response.body)

    # slack returns status_code 200 for some errors
    unless body["ok"] do
      raise SlackApi.Error, response
    end

    body
  end

  def post!(url, body, headers) do
    response = HTTPoison.post!(url, body, headers)

    if response.status_code != 200 do
      raise SlackApi.Error, response
    end

    body =
      response.body
      |> Jason.decode!()

    # slack returns status_code 200 for some errors
    unless body["ok"] do
      raise SlackApi.Error, response
    else
      :ok
    end
  end
end
