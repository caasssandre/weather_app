defmodule WeatherApp.Server do
  use GenServer
  # @repeat_frequency_in_ms 60_000
  @repeat_frequency_in_ms 20_000

  @moduledoc """
  This server receives a call with a city and sends a response containing the temperature to the client every 10 minutes
  """

  @spec start_link(name: binary()) :: :ignore | {:error, any()} | {:ok, pid()}
  def start_link(opts) do
    GenServer.start_link(__MODULE__, nil, opts)
  end

  # @spec city_temp(binary()) :: any()
  def city_temp(pid \\ __MODULE__, city) do
    GenServer.call(pid, {:city, city})
  end

  @impl GenServer
  def init(_opts), do: {:ok, []}

  @impl GenServer
  # move city to state
  def handle_call({:city, city}, {client_pid, _alias}, _state) do
    Process.send(client_pid, {:city_temp, request_city_temp_and_analyse_response(city)}, [])
    Process.send_after(self(), %{city: city, client_pid: client_pid}, @repeat_frequency_in_ms)
    {:reply, {:city, city}, []}
  end

  @impl GenServer
  def handle_info(%{city: city, client_pid: client_pid}, _state) do
    Process.send(client_pid, {:city_temp, request_city_temp_and_analyse_response(city)}, [])
    Process.send_after(self(), %{city: city, client_pid: client_pid}, @repeat_frequency_in_ms)

    {:noreply, []}
  end

  # use mise to load env file ?
  def request_city_temp_and_analyse_response(city) do
    request =
      Finch.build(
        :get,
        "https://weather.visualcrossing.com/VisualCrossingWebServices/rest/services/timeline/" <>
          String.replace(city, " ", "_") <>
          "?unitGroup=metric&include=current&key=" <>
          Application.fetch_env!(:weather_app, :api_key) <>
          "&contentType=json"
      )

    with {:ok, %{status: 200, body: body}} <- Finch.request(request, WeatherApp.Finch),
         {:ok, json} <- Jason.decode(body),
         {:ok, connies} <- Map.fetch(json, "currentConditions"),
         {:ok, temp} <- Map.fetch(connies, "temp") do
      {:ok, temp}
    else
      {:ok, %{status: _, body: body}} -> {:error, :bad_request, body}
      {:error, :bad_request, reason} -> {:error, :bad_request, reason}
      {:error, %Mint.HTTPError{}} -> {:error, :invalid_request_format}
      {:error, %Jason.DecodeError{}} -> {:error, :invalid_json}
      _ -> {:error, :unknown_error}
    end
  end
end
