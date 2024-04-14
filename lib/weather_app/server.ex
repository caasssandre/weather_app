defmodule WeatherApp.Server do
  @moduledoc """
  This server receives a call with a city
  and sends a response containing the temperature to the client every 10 minutes.
  """

  use GenServer
  # @repeat_frequency_in_ms 60_000
  @repeat_frequency_in_ms 2_000
  @weather_uri_host "weather.visualcrossing.com"
  @weather_uri_path "/VisualCrossingWebServices/rest/services/timeline/"

  @spec start_link(name: binary()) :: :ignore | {:error, any()} | {:ok, pid()}
  def start_link(opts) do
    GenServer.start_link(__MODULE__, nil, opts)
  end

  @impl GenServer
  def init(_opts), do: {:ok, []}

  @impl GenServer
  def handle_info({:local_temperature, [client_pid: client_pid, city: city]}, []) do
    Process.send(
      client_pid,
      request_temperature(city),
      []
    )

    Process.send_after(
      self(),
      {:local_temperature, [client_pid: client_pid, city: city]},
      @repeat_frequency_in_ms
    )

    {:noreply, []}
  end

  # 8&^%yhg
  defp request_temperature(city) do
    request =
      Finch.build(
        :get,
        build_uri(city)
      )

    with {:ok, %{status: 200, body: body}} <- Finch.request(request, WeatherApp.Finch),
         {:ok, json} <- Jason.decode(body),
         {:ok, conditions} <- Map.fetch(json, "currentConditions"),
         {:ok, temp} <- Map.fetch(conditions, "temp") do
      {:ok, temp}
    else
      {:ok, %{status: _, body: body}} -> {:error, :bad_request, body}
      {:error, :bad_request, reason} -> {:error, :bad_request, reason}
      {:error, %Mint.HTTPError{}} -> {:error, :network_error}
      {:error, %Jason.DecodeError{}} -> {:error, :invalid_json}
      unknown_error -> IO.inspect(unknown_error)
    end
  end

  defp build_uri(city) do
    query = %{
      unitGroup: "metric",
      include: "current",
      key: Application.fetch_env!(:weather_app, :api_key),
      contentType: "json"
    }

    %URI{
      scheme: "https",
      host: @weather_uri_host,
      path: @weather_uri_path <> URI.encode(city),
      query: URI.encode_query(query)
    }
    |> URI.to_string()
  end
end
