defmodule WeatherApp.Client do
  use Task
  alias WeatherApp.Server

  @moduledoc """
  This console UI takes a city name input from a user and prints the current
  temperature for that city every 10 minutes.
  """

  @spec start_link(any()) :: {:ok, pid()}
  def start_link(_) do
    Task.start_link(fn -> ask_for_city_input() end)
  end

  defp ask_for_city_input() do
    IO.gets("Enter a city name\n")
    |> String.trim()
    |> request_temp()
  end

  defp request_temp(city) do
    case Server.city_temp(city) do
      {:ok, temp} ->
        IO.puts("It is currently #{temp} degrees celsius in #{city}")
        # 600,000 ms
        :timer.sleep(2000)
        request_temp(city)

      {:error, :bad_request, reason} ->
        IO.puts("The request was not formed correctly " <> reason)
        System.halt(0)

      {:error, :invalid_json} ->
        IO.puts("The JSON returned from the API was malformed")
        System.halt(0)

      {:error, _} ->
        IO.puts("Unknown error #{city}.")
        System.halt(0)
    end
  end
end
