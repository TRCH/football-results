defmodule FootballResults.Application do

  use Application
  require Logger

  def start(_type, _args) do
    cowboy_http_port = 8081

    children = [
      FootballResults.Repo,
      {Plug.Cowboy, scheme: :http, plug: FootballResults.Router, options: [port: cowboy_http_port]},
    ]

    Logger.info("Starting application. Cowboy will listening on port #{cowboy_http_port}")
    Supervisor.start_link(children, strategy: :one_for_one)
  end
end
