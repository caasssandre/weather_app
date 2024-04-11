defmodule WeatherApp.Server do
  use GenServer

  @moduledoc """
  This server receives a call with a city and returns {:ok, temp} or {:error, reason}
  """

  @spec start_link(any()) :: :ignore | {:error, any()} | {:ok, pid()}
  def start_link(_opts) do
    GenServer.start_link(__MODULE__, nil, name: __MODULE__)
  end

  @spec city_temp(binary()) :: any()
  def city_temp(pid \\ __MODULE__, city) do
    GenServer.call(pid, {:city, city})
  end

  @impl GenServer
  @spec init(any()) :: {:ok, []}
  def init(_opts), do: {:ok, []}

  @impl GenServer
  @spec handle_call({:city, binary()}, any(), any()) ::
          {:reply, {:error, :invalid_json | :unknown_error} | {:ok, binary()}, any()}
  def handle_call({:city, city}, _from, _state) do
    case show_city_temp(city) do
      {:ok, temp} -> {:reply, {:ok, temp}, []}
      {:error, reason} -> {:reply, {:error, reason}, []}
    end
  end

  defp show_city_temp(city) do
    api_key = Application.fetch_env!(:weather_app, :api_key)

    request =
      Finch.build(
        :get,
        "https://weather.visualcrossing.com/VisualCrossingWebServices/rest/services/timeline/" <>
          city <>
          "?unitGroup=metric&include=current&key=" <>
          api_key <>
          "&contentType=json"
      )

    with {:ok, %{status: 200, body: body}} <- Finch.request(request, WeatherApp.Finch),
         {:ok, json} <- Jason.decode(body),
         {:ok, connies} <- Map.fetch(json, "currentConditions"),
         {:ok, temp} <- Map.fetch(connies, "temp") do
      {:ok, temp}
    else
      {:ok, %{status: _, body: body}} -> {:error, :bad_request, body}
      {:error, %Jason.DecodeError{}} -> {:error, :invalid_json}
      :error -> {:error, :unknown_error}
    end
  end
end