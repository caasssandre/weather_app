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
    |> Server.city_temp()
    |> loop()
  end

  def loop({:ok, %{city: city}}) do
    receive do
      resp ->
        case handle_response_for_display(resp, city) do
          {:ok, display_text} ->
            IO.puts(display_text)

          {:error, display_text} ->
            IO.puts(display_text)
            System.halt(0)
        end

        loop({:ok, %{city: city}})
    end
  end

  defp handle_response_for_display(resp, city) do
    case resp do
      {:ok, temp} ->
        {:ok, "At #{human_readable_time()}, it was #{temp} degrees celsius in #{city}"}

      {:error, :bad_request, reason} ->
        {:error, "The request was not formed correctly " <> reason}

      {:error, :invalid_json} ->
        {:error, "The JSON returned from the API was malformed"}

      {:error, :invalid_request_format} ->
        {:error, "Invalid request format."}

      {:error, _} ->
        {:error, "Unknown error #{city}."}
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
