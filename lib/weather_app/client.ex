defmodule WeatherApp.Client do
  @moduledoc """
  This console UI requests a city name from the user, send it to the server
  and prints the temperature every time the server sends it.
  """
  use Task
  alias WeatherApp.Server

  @spec start_link(any()) :: {:ok, pid()}
  def start_link(_) do
    Task.start_link(fn -> ask_for_city_input() end)
  end

  defp ask_for_city_input() do
    city =
      IO.gets("Enter a city name\n")
      |> String.trim()

    Process.send(
      Server,
      {:local_temperature, [client_pid: self(), city: city]},
      []
    )

    loop(city)
  end

  def loop(city) do
    receive do
      response ->
        case render_response(response, city) do
          {:ok, display_text} ->
            IO.puts(display_text)
            loop(city)

          {:error, display_text} ->
            IO.puts(display_text)
            System.halt(0)
        end
    end
  end

  defp render_response({:ok, temp}, city),
    do: {:ok, "At #{human_readable_nz_time()}, it was #{temp} degrees celsius in #{city}"}

  defp render_response({:error, :bad_request, reason}, _city),
    do: {:error, "The request was not formed correctly " <> inspect(reason)}

  defp render_response({:error, :invalid_json}, _city),
    do: {:error, "The JSON returned from the API was malformed"}

  defp render_response({:error, :network_error}, _city),
    do: {:error, "Network error"}

  defp human_readable_nz_time() do
    %{hour: hour, minute: minute} = DateTime.utc_now()
    nz_hour = if hour > 11, do: hour - 12, else: hour + 12

    "#{nz_hour}:#{String.pad_leading("#{minute}", 2, "0")}"
  end
end
