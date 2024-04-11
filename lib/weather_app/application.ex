defmodule WeatherApp.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      {Finch, name: WeatherApp.Finch},
      {WeatherApp.Server, name: WeatherApp.Server},
      WeatherApp.Client
      # Starts a worker by calling: WeatherApp.Worker.start_link(arg)
      # {WeatherApp.Worker, arg}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: WeatherApp.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
