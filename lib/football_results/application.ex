defmodule FootballResults.Application do

  use Application
  require Logger

  def start(_type, _args) do
    children = [
      {Plug.Cowboy, scheme: :http, plug: FootballResults.Router, options: [port: 8080]}
    ]

    Logger.info("Started application")
    Supervisor.start_link(children, strategy: :one_for_one)
  end
end
