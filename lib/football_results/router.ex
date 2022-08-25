defmodule FootballResults.Router do
  use Plug.Router
  require Logger

  plug(:match)
  plug(:dispatch)

  def init(options), do: options

  get "/league" do
    case get_req_header(conn, "accept") do
      ["application/json"] ->
        handle_league_request(conn)
      unsupported_accept ->
        handle_unsupported_accept(conn, unsupported_accept)
    end
  end

  match(_, do: send_resp(conn, 404, "Oops!"))


  defp handle_league_request(conn) do
    league_season_pairs = FootballResults.Repo.lookup_league_season_pairs()

    structs = for {league, season} <- league_season_pairs do
      %FootballResults.LeagueSeasonPairs{league: league, season: season}
    end

    json = Poison.encode!(structs)

    conn
    |> put_resp_content_type("application/json")
    |> send_resp(200, json)
  end


  # enable after dev
  defp handle_unsupported_accept(conn, unsupported_accept) do
    Logger.warn("Accept header #{unsupported_accept} not supported")
    put_status(conn, 406)
  end

end
