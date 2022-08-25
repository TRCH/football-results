defmodule FootballResults.RouterTest do
  use ExUnit.Case
  use Plug.Test

  @opts FootballResults.Router.init([])

  test "returns league and season pairs" do
      conn =
        conn(:get, "/league", "")
        |> put_req_header("accept", "application/json")
        |> FootballResults.Router.call(@opts)

      assert conn.state == :sent
      assert conn.status == 200

      IO.puts(Poison.decode!(conn.resp_body, as: %FootballResults.LeagueSeasonPairs{}))
  end

  test "returns 406 when league and season pairs called with unsupported accept" do
      conn =
        conn(:get, "/league", "")
        |> put_req_header("accept", "application/xml")
        |> FootballResults.Router.call(@opts)

      assert conn.status == 406
  end

end
