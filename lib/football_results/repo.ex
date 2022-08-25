defmodule FootballResults.Repo do

  # quick prototyping
  def lookup_league_season_pairs do
    path = Path.join(:code.priv_dir(:football_results), "football_results.csv")

    # todo clean up and find way to skip first element
    File.stream!(path)
    |> Enum.reduce(MapSet.new(), fn(line, acc) ->
      [_, division, season, _, _, _, _, _, _, _, _, _] = String.split(line, ",")

      division = String.replace(division, "\"", "", global: true)
      season = String.replace(season, "\"", "", global: true)

      MapSet.put(acc, {division, season})
    end)

  end

end
