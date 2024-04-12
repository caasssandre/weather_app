defmodule WeatherAppServerTest do
  use ExUnit.Case, async: false
  use Mimic

  alias WeatherApp.Server

  setup :set_mimic_global

  describe "request_city_temp_and_analyse_response/1" do
    test "returns {:ok, temp} with a valid request" do
      expect(Finch, :request, fn _request, _server_name ->
        {:ok, %{status: 200, body: "{\"currentConditions\":{\"temp\":12.7}}"}}
      end)

      parent_pid = self()

      spawn_link(fn ->
        assert {:ok, 12.7} = Server.request_city_temp_and_analyse_response("london")

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
                 Server.request_city_temp_and_analyse_response("onlyletters")

        send(parent_pid, :ok)
      end)

      assert_receive :ok
    end

    test "returns {:error, :invalid_request_format} if the request was badly formatted" do
      expect(Finch, :request, fn _request, _server_name ->
        {:error, %Mint.HTTPError{}}
      end)

      parent_pid = self()

      spawn_link(fn ->
        assert {:error, :invalid_request_format} =
                 Server.request_city_temp_and_analyse_response("BadFormat")

        send(parent_pid, :ok)
      end)

      assert_receive :ok
    end

    test "returns {:error, :invalid_json} if the API returns invalid Json" do
      expect(Finch, :request, fn _request, _server_name ->
        {:error, %Jason.DecodeError{}}
      end)

      parent_pid = self()

      spawn_link(fn ->
        assert {:error, :invalid_json} =
                 Server.request_city_temp_and_analyse_response("cityname")

        send(parent_pid, :ok)
      end)

      assert_receive :ok
    end

    test "sends the request with the corrected city name when name contains a space" do
      expect(Finch, :request, fn request, _server_name ->
        assert request.path == "/VisualCrossingWebServices/rest/services/timeline/New_York"
        {:ok, %{status: 200, body: "{\"currentConditions\":{\"temp\":22.7}}"}}
      end)

      parent_pid = self()

      spawn_link(fn ->
        assert {:ok, 22.7} =
                 Server.request_city_temp_and_analyse_response("New York")

        send(parent_pid, :ok)
      end)

      assert_receive :ok
    end
  end
end
