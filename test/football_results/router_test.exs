defmodule FootballResults.RouterTest do
  use ExUnit.Case
  use Plug.Test

  @opts FootballResults.Router.init([])

  # constants
  @application_protobuf "application/x-protobuf"
  @application_json "application/json"

  test "returns division and season pairs when accept header is #{@application_json}" do

    expected_decoded_resp_body = [
      %{"division" => "D1", "season" => "201617"},
      %{"division" => "E0", "season" => "201617"},
      %{"division" => "SP1", "season" => "201516"},
      %{"division" => "SP1", "season" => "201617"},
      %{"division" => "SP2", "season" => "201516"},
      %{"division" => "SP2", "season" => "201617"}
    ]

    conn =
      conn(:get, "/league", "")
      |> put_req_header("accept", @application_json)
      |> FootballResults.Router.call(@opts)

    assert conn.state == :sent
    assert conn.status == 200

    decoded_resp_body = Poison.decode!(conn.resp_body)
    assert decoded_resp_body == expected_decoded_resp_body
  end

  test "return the results for a division and season pair when accept header is #{@application_json}" do
    division = "D1"
    season = "201617"

    conn =
      conn(:get, "/league/#{division}/#{season}", "")
      |> put_req_header("accept", @application_json)
      |> FootballResults.Router.call(@opts)

    assert conn.state == :sent
    assert conn.status == 200

    decoded_body = Poison.decode!(conn.resp_body)
    actual_number_results = length(decoded_body)
    expected_number_results = 306
    assert actual_number_results == expected_number_results

    ## response huge, check some samples
    ## for a production application we would checking everything
    expected_result_1 = %{"away_team" => "Werder Bremen", "date" => "26/08/16", "full_time_away_team_goals" => 0,
    "full_time_home_team_goals" => 6, "full_time_result" => "H", "half_time_away_team_goals" => 0,
    "half_time_home_team_goals" => 2, "half_time_result" => "H", "home_team" => "Bayern Munich"}
    assert expected_result_1 in decoded_body

    expected_result_2 = %{"away_team" => "M'gladbach", "date" => "21/09/16", "full_time_away_team_goals" => 1,
    "full_time_home_team_goals" => 1, "full_time_result" => "D", "half_time_away_team_goals" => 0,
    "half_time_home_team_goals" => 1, "half_time_result" => "H", "home_team" => "RB Leipzig"}
    assert expected_result_2 in decoded_body

    expected_result_3 = %{"away_team" => "Leverkusen", "date" => "17/09/16", "full_time_away_team_goals" => 1,
    "full_time_home_team_goals" => 2, "full_time_result" => "H", "half_time_away_team_goals" => 0,
    "half_time_home_team_goals" => 0, "half_time_result" => "D", "home_team" => "Ein Frankfurt"}
    assert expected_result_3 in decoded_body
  end

  test "returns division and season pairs when accept header is #{@application_protobuf}" do
    expected_decoded_resp_body = %FootballResults.Protobuf.DivisionSeasonPairList{
        division_season_pairs: [
          %FootballResults.Protobuf.DivisionSeasonPair{division: "D1", season: "201617"},
          %FootballResults.Protobuf.DivisionSeasonPair{division: "E0", season: "201617"},
          %FootballResults.Protobuf.DivisionSeasonPair{division: "SP1", season: "201516"},
          %FootballResults.Protobuf.DivisionSeasonPair{division: "SP1", season: "201617"},
          %FootballResults.Protobuf.DivisionSeasonPair{division: "SP2", season: "201516"},
          %FootballResults.Protobuf.DivisionSeasonPair{division: "SP2", season: "201617"}
        ]
      }

    conn =
      conn(:get, "/league", "")
      |> put_req_header("accept", @application_protobuf)
      |> FootballResults.Router.call(@opts)

    assert conn.state == :sent
    assert conn.status == 200

    decoded_resp_body = FootballResults.Protobuf.DivisionSeasonPairList.decode(conn.resp_body)
    assert decoded_resp_body == expected_decoded_resp_body

  end

  test "return the results for a division and season pair when accept header is #{@application_protobuf}" do
    division = "SP1"
    season = "201617"

    conn =
      conn(:get, "/league/#{division}/#{season}", "")
      |> put_req_header("accept", @application_protobuf)
      |> FootballResults.Router.call(@opts)

    assert conn.state == :sent
    assert conn.status == 200

    decoded_resp_body = FootballResults.Protobuf.ResultList.decode(conn.resp_body)

    actual_numner_results = length(decoded_resp_body.results)
    expected_number_results = 380

    assert actual_numner_results == expected_number_results

    ## response huge, check some samples
    ## for a production application we would checking everything
    expected_result_1 = %FootballResults.Protobuf.Result{away_team: "Malaga",
    date: "17/09/16", full_time_away_team_goals: 0, full_time_home_team_goals: 1,
    full_time_result: :H, half_time_away_team_goals: 0, half_time_home_team_goals: 1,
    half_time_result: :H, home_team: "Las Palmas"}
    assert expected_result_1 in decoded_resp_body.results

    expected_result_2 = %FootballResults.Protobuf.Result{away_team: "Barcelona",
    date: "17/09/16", full_time_away_team_goals: 5, full_time_home_team_goals: 1,
    full_time_result: :A, half_time_away_team_goals: 3, half_time_home_team_goals: 0,
    half_time_result: :A, home_team: "Leganes"}
    assert expected_result_2 in decoded_resp_body.results

    expected_result_3 = %FootballResults.Protobuf.Result{away_team: "Valencia",
    date: "18/09/16", full_time_away_team_goals: 1, full_time_home_team_goals: 2,
    full_time_result: :H, half_time_away_team_goals: 1, half_time_home_team_goals: 2,
    half_time_result: :H, home_team: "Ath Bilbao"}
    assert expected_result_3 in decoded_resp_body.results

  end

  test "returns HTTP 204 when there are no results for a division and season pair" do
    # pair do not exist
    division = "SP3"
    season = "201617"

    conn =
      conn(:get, "/league/#{division}/#{season}", "")
      |> put_req_header("accept", @application_protobuf)
      |> FootballResults.Router.call(@opts)

    assert conn.status == 204
  end

  test "returns 406 when division and season pairs called with unsupported accept" do
      conn =
        conn(:get, "/league", "")
        |> put_req_header("accept", "application/xml")
        |> FootballResults.Router.call(@opts)

      assert conn.status == 406
  end

end
