defmodule WeatherAppServerTest do
  use ExUnit.Case, async: false
  use Mimic

  alias WeatherApp.Server

  doctest WeatherApp.Server

  setup :set_mimic_global

  describe "city_temp/2" do
    test "returns {:ok, temp} with a valid request" do
      expect(Finch, :request, fn _request, _server_name ->
        {:ok, %{status: 200, body: "{\"currentConditions\":{\"temp\":12.7}}"}}
      end)

      parent_pid = self()

      spawn_link(fn ->
        assert {:ok, 12.7} = Server.city_temp("london")

        send(parent_pid, :ok)
      end)

      assert_receive :ok
    end

    test "returns {:error, :bad_request, reason} with an invalid city name" do
      expect(Finch, :request, fn _request, _server_name ->
        {:ok, %{status: 400, body: "Bad API Request:Invalid location parameter value."}}
      end)

      parent_pid = self()

      spawn_link(fn ->
        assert {:error, :bad_request, "Bad API Request:Invalid location parameter value."} =
                 Server.city_temp("onlyletters")

        send(parent_pid, :ok)
      end)

      assert_receive :ok
    end
  end
end
