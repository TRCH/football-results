defmodule FootballResults.LeagueSeasonPairs do
    @derive [Poison.Encoder]
    defstruct [:league, :season]
end
