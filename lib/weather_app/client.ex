defmodule WeatherApp.Client do
  use Task
  alias WeatherApp.Server

  # @repeat_frequency_in_ms 600_000
  @repeat_frequency_in_ms 2_000

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
    |> request_city_temp_and_display()
  end

  defp request_city_temp_and_display(city) do
    case Server.city_temp(city) do
      {:ok, temp} ->
        IO.puts("At #{human_readable_time()}, it was #{temp} degrees celsius in #{city}")

        :timer.sleep(@repeat_frequency_in_ms)
        request_city_temp_and_display(city)

      {:error, :bad_request, reason} ->
        IO.puts("The request was not formed correctly " <> reason)
        System.halt(0)

      {:error, :invalid_json} ->
        IO.puts("The JSON returned from the API was malformed")
        System.halt(0)

      {:error, :invalid_request_format} ->
        IO.puts("Invalid request format.")
        System.halt(0)

      {:error, _} ->
        IO.puts("Unknown error #{city}.")
        System.halt(0)
    end
  end

  defp human_readable_time() do
    %{hour: hour, minute: minute} = DateTime.utc_now()

    nz_hour =
      if hour > 11 do
        hour - 12
      else
        hour + 12
      end

    human_minutes =
      if minute < 10 do
        "0#{minute}"
      else
        minute
      end

    "#{nz_hour}:#{human_minutes}"
  end
end
