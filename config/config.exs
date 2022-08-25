use Mix.Config

import_config "#{Mix.env()}.exs"

# request_id is set by Plug.RequestId
config :logger, :console,
  format: "\n$time $levelpad$message $metadata\n",
  metadata: [:module, :function, :line, :request_id]

config :folsom, meter: ["football_results.get_league", 
                        "football_results.get_results"]
