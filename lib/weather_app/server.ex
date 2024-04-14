defmodule WeatherApp.Server do
  @moduledoc """
  This server receives a call with a city
  and sends a response containing the temperature to the client every 10 minutes.
  """

  use GenServer
  # @repeat_frequency_in_ms 60_000
  @repeat_frequency_in_ms 20_000

  @spec start_link(name: binary()) :: :ignore | {:error, any()} | {:ok, pid()}
  def start_link(opts) do
    GenServer.start_link(__MODULE__, nil, opts)
  end

  @spec city_temp(binary()) :: any()
  def city_temp(pid \\ __MODULE__, city) do
    GenServer.call(pid, {:city, city})
  end

  @impl GenServer
  def init(_opts), do: {:ok, []}

  # handle call uses same name as function above
  @impl GenServer
  def handle_call({:city, city}, {client_pid, _alias}, _state) do
    Process.send(
      client_pid,
      request_temperature(city),
      []
    )

    Process.send_after(self(), [], @repeat_frequency_in_ms)
    {:reply, {:ok, %{city: city}}, %{city: city, client_pid: client_pid}}
  end

  @impl GenServer
  def handle_info(_, %{client_pid: client_pid, city: city}) do
    Process.send(
      client_pid,
      request_temperature(city),
      []
    )

    Process.send_after(self(), [], @repeat_frequency_in_ms)
    {:noreply, %{client_pid: client_pid, city: city}}
  end

  defp request_temperature(city) do
    request =
      Finch.build(
        :get,
        "https://weather.visualcrossing.com/VisualCrossingWebServices/rest/services/timeline/" <>
          String.replace(city, " ", "_") <>
          "?unitGroup=metric&include=current&key=" <>
          Application.fetch_env!(:weather_app, :api_key) <>
          "&contentType=json"
      )

    # URL base in module var, default params into module var as a map
    # URI module
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
end
