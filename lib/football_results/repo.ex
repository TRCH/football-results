defmodule FootballResults.Repo do
  @moduledoc """
  A GenServer that on startup reads football_results.csv, builds a datastructure and stores it in the state.
  Users can perform lookups via this module.
  """
  use GenServer

  @type division :: String.t()
  @type season :: String.t()

  @type division_season_map :: %{
    division: division(),
    season: season()
  }

  @type results_map :: %{
    date: String.t(),
    home_team: String.t(),
    away_team: String.t(),
    full_time_home_team_goals: non_neg_integer(),
    full_time_away_team_goals: non_neg_integer(),
    full_time_result: String.t(),
    half_time_home_team_goals: non_neg_integer(),
    half_time_away_team_goals: non_neg_integer(),
    half_time_result: String.t()
  }

  def start_link(_args) do
    GenServer.start_link(__MODULE__, nil, [name: __MODULE__])
  end

  def init(_state) do
    # hard coded path to make code easier to review
    football_results_csv_path = Path.join(:code.priv_dir(:football_results), "football_results.csv")
    state = parse_football_results_csv(football_results_csv_path)

    {:ok, state}
  end

  @spec lookup_division_season_pairs() :: [division_season_map()]
  def lookup_division_season_pairs do
    GenServer.call(__MODULE__, :lookup_division_season_pairs)
  end

  @spec lookup_results(division(), season()) :: results_map() | nil
  def lookup_results(division, season) do
    GenServer.call(__MODULE__, {:lookup_results, division, season})
  end

  def handle_call(:lookup_division_season_pairs, _from, state) do
    division_season_pairs = state
                          |> Map.keys()
                          |> Enum.map(fn({division, season}) ->
                              %{division: division, season: season}
                            end)

    {:reply, division_season_pairs, state}
  end

  def handle_call({:lookup_results, division, season}, _from, state) do
    composite_key = {division, season}
    results = state[composite_key]

    {:reply, results, state}
  end

  defp parse_football_results_csv(football_results_csv_path) do
    File.stream!(football_results_csv_path)
    |> Enum.drop(1) # first row is column names
    |> Enum.reduce(%{}, fn(line, acc) ->
      {division, season, result} = parse_football_results_csv_line(line)

      # data structure tailered towards requirements
      composite_key = {division, season}
      result_entry = [result]

      # if already result for composite_key then update result list
      Map.update(acc, composite_key, result_entry, &(&1 ++ result_entry))
    end)
  end

  defp parse_football_results_csv_line(line) do
    [_row_number, division, season, date,
     home_team, away_team, fthg, ftag,
     ftr, hthg, htag, htr] = parse_and_cleanup(line)

     result = %{
       date: date,
       home_team: home_team,
       away_team: away_team,
       full_time_home_team_goals: String.to_integer(fthg),
       full_time_away_team_goals: String.to_integer(ftag),
       full_time_result: ftr,
       half_time_home_team_goals: String.to_integer(hthg),
       half_time_away_team_goals: String.to_integer(htag),
       half_time_result: htr
     }

     {division, season, result}
  end

  defp parse_and_cleanup(line) do
    String.split(line, ",")
    |> Stream.map(&String.replace(&1, "\"", "", global: true))
    |> Stream.map(&String.replace(&1, "\n", "", global: true))
    |> Enum.to_list()
  end

end
