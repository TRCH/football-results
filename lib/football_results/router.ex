defmodule FootballResults.Router do
  @moduledoc """
  Entry point to the HTTP API. The API produces json and protobuf.
  Specify which in the accept header.

  For simplicity the module has multiple responsibilities.
  """

  require Logger

  use Plug.Router

  # header value constants
  @application_json "application/json"
  @application_protobuf "application/x-protobuf"

  # status code constants
  @http_200 200
  @http_204 204
  @http_406 406

  plug Plug.RequestId
  plug Plug.Logger

  plug(:match)
  plug(:dispatch)

  def init(options), do: options

  get "/league" do
    FootballResults.Metrics.increment_get_league_meter()

    case get_req_header(conn, "accept") do
      [@application_json] ->
        handle_league_request_return_json(conn)
      [@application_protobuf] ->
        handle_league_request_return_protobuf(conn)
      unsupported_accept ->
        handle_unsupported_accept(conn, unsupported_accept)
    end
  end

  get "/league/:division/:season" do
    FootballResults.Metrics.increment_get_results_meter()

    [accept] = get_req_header(conn, "accept")

    case accept do
      accept when accept in [@application_json, @application_protobuf] ->
        handle_lookup_results(conn, division, season, accept)
      unsupported_accept ->
        handle_unsupported_accept(conn, unsupported_accept)
    end
  end

  match(_, do: put_status(conn, 404))

  defp handle_league_request_return_json(conn) do
    division_season_pairs = FootballResults.Repo.lookup_division_season_pairs()
    json = Poison.encode!(division_season_pairs)

    conn
    |> put_resp_content_type(@application_json)
    |> send_resp(@http_200, json)
  end

  def handle_league_request_return_protobuf(conn) do
    division_season_pairs = FootballResults.Repo.lookup_division_season_pairs()

    division_season_pair_protobuf = for %{division: division, season: season} <- division_season_pairs do
      FootballResults.Protobuf.DivisionSeasonPair.new(division: division, season: season)
    end

    division_season_pair_list_protobuf = FootballResults.Protobuf.DivisionSeasonPairList.new(division_season_pairs: division_season_pair_protobuf)
    protobuf_binary = FootballResults.Protobuf.DivisionSeasonPairList.encode(division_season_pair_list_protobuf)

    conn
    |> put_resp_content_type(@application_protobuf)
    |> send_resp(@http_200, protobuf_binary)
  end

  def handle_lookup_results(conn, division, season, accept) do
    results = FootballResults.Repo.lookup_results(division, season)

    # do we have results?
    case results do
      nil ->
        put_status(conn, @http_204)

      results ->
        # accept header determines what we build
        case accept do
          @application_json ->
            results_to_json(conn, results)
          @application_protobuf ->
            results_to_protobuf(conn, results)
        end
    end
  end

  def results_to_json(conn, results) do
    json = Poison.encode!(results)

    conn
    |> put_resp_content_type(@application_json)
    |> send_resp(@http_200, json)
  end

  def results_to_protobuf(conn, results) do
    results_protobuf = for result <- results do
                            FootballResults.Protobuf.Result.new(date: result[:date],
                                                                home_team: result[:home_team],
                                                                away_team: result[:away_team],
                                                                full_time_home_team_goals: result[:full_time_home_team_goals],
                                                                full_time_away_team_goals: result[:full_time_away_team_goals],
                                                                full_time_result: outcome(result[:full_time_result]),
                                                                half_time_home_team_goals: result[:half_time_home_team_goals],
                                                                half_time_away_team_goals: result[:half_time_away_team_goals],
                                                                half_time_result: outcome(result[:half_time_result])
                                                                )
                        end

    result_list_protobuf = FootballResults.Protobuf.ResultList.new(results: results_protobuf)
    protobuf_binary = FootballResults.Protobuf.ResultList.encode(result_list_protobuf)

    conn
    |> put_resp_content_type(@application_protobuf)
    |> send_resp(@http_200, protobuf_binary)
  end

  defp outcome("H"), do: :H
  defp outcome("A"), do: :A
  defp outcome("D"), do: :D

  defp handle_unsupported_accept(conn, unsupported_accept) do
    Logger.warn("Accept header #{unsupported_accept} not supported")
    put_status(conn, @http_406)
  end

end
