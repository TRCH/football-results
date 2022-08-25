defmodule FootballResults.Protobuf do
  use Protobuf, from: Path.wildcard(Path.expand("../../proto/*.proto", __DIR__))
end
