defmodule FootballResults.Metrics do
  @moduledoc """
  Thin client for sending metrics to folsom.
  """

  @increment_by_1 1

  def increment_get_league_meter do
    counter = "football_results.get_league"
    :folsom_metrics.notify({counter, @increment_by_1})
  end

  def increment_get_results_meter do
    counter = "football_results.get_results"
    :folsom_metrics.notify({counter, @increment_by_1})
  end
end
