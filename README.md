# FootballResults

:football_results is a simple application that allows users to look up division/season pairings and football results.

The application is written in Elixir and uses Plug with Cowboy to serve the football information via HTTP. Users can (via accept HTTP header) specify to receive the data as json or protobuf.

HTTP requests are handled by the FootballResults.Router module, this does the lookup using the FootballResults.Repo (GenServer) module. During initialisation FootballResults.Repo will read and build it's data structure (i.e. process state) from ./priv/football_results.csv. FootballResults.Metrics sends application metrics (e.g. HTTP endpoint hit rate) to graphite via folsomite.

## Getting Started

** Prerequisites **

:football_results was developed with the following. Older or newer versions may work but haven't been tested.

- Erlang 21.1
- Elixir 1.7.4
- GNU Make 3.81
- Docker 18.09.0
- docker-compose 1.23.1

Fetch the dependencies, compile the project and run the tests.

```bash
mix deps.get
mix compile
mix test
```

There are 3 ways to run the :football_results application; on your host, as a docker container or in high availability HAProxy load balancing between 3 instances (Docker containers) of :football_results. The reasons for each and how to run them are explained below.

#### Running :football_results on your host

This is useful for quickly checking changes to your code. To make an HTTP request to :football_results use localhost:8081

```bash
mix run --no-halt
```

#### Running :football_results with Docker

This is useful for checking changes to your Dockerfile worked. First you need to build the container, then you can start. To make an HTTP request to :football_results use localhost:8080.

```bash
make build-app-image
make start-graphite # optional
make start-app
```

Get the container id to stop it.

```bash
docker ps
CONTAINER ID     IMAGE
2d643d8d16f7     football-results:latest

docker stop 2d643d8d16f7
```

#### Running :football_results with HA

This is useful for running :football_results in a production environment. First build the image, create a Docker Swarm and then start everything. This will start 3 instances of :football_results, HAProxy and Graphite. To make an HTTP request to :football_results use localhost:8080.

```bash
make build-app-image
make create-docker-swarm # only run first time
make start-app-ha # uses docker-compose
```

Check the logs.

```bash

make app-logs-ha
docker service logs prod_football-results
prod_football-results.1    | 19:00:33.395  Starting application. Cowboy will listening on port 8081 module=FootballResults.Application function=start/2 line=14
prod_football-results.2    | 19:00:33.012  Starting application. Cowboy will listening on port 8081 module=FootballResults.Application function=start/2 line=14
prod_football-results.3    | 19:00:33.256  Starting application. Cowboy will listening on port 8081 module=FootballResults.Application function=start/2 line=14
```

Stop everything

```bash
make stop-app-ha
```

## HTTP API

### /league

Return division/season pairs.

- Request Headers
  - (required) Accept: application/json OR application/x-protobuf
  - (optional) x-request-id

- Status codes
  - 200 - Success
  - 406 - Accept not supported
- JSON Request
  ```
  # 8081 for running on host, 8080 otherwise
  curl -H "Accept: application/json" "http://localhost:8080/league"
  ```
- JSON Response  
  ```javascript
  [
    {
      "season": "201617",
      "division": "D1"
    },
    {
      "season": "201617",
      "division": "E0"
    }
  ]
  ```
- Protobuf Request
  ```
  # 8081 for running on host, 8080 otherwise
  curl -H "Accept: application/x-protobuf" "http://localhost:8080/league"
  ```

- Protobuf Response  
  See ./proto/division_season_pairs.proto

  ### /league/:division/:season

  Returns results for given division and season.

  - Path params
    - division - The division e.g. D1
    - season - The season e.g. 201617
  - Request Headers
    - (required) Accept: application/json OR application/x-protobuf
    - (optional) x-request-id

  - Status codes
    - 200 - Success
    - 204 - Results don't exist for given division and season
    - 406 - Accept not supported
  - JSON Request
    ```
    # 8081 for running on host, 8080 otherwise
    curl -H "Accept: application/json" "http://localhost:8080/league/D1/201617"
    ```
  - JSON Response  
    ```javascript
    [
      {
      "home_team": "Ingolstadt",
      "half_time_result": "D",
      "half_time_home_team_goals": 1,
      "half_time_away_team_goals": 1,
      "full_time_result": "D",
      "full_time_home_team_goals": 1,
      "full_time_away_team_goals": 1,
      "date": "20/05/17",
      "away_team": "Schalke 04"
    },
    {
      "home_team": "M'gladbach",
      "half_time_result": "D",
      "half_time_home_team_goals": 0,
      "half_time_away_team_goals": 0,
      "full_time_result": "D",
      "full_time_home_team_goals": 2,
      "full_time_away_team_goals": 2,
      "date": "20/05/17",
      "away_team": "Darmstadt"
    }
  ]
    ```
  - Protobuf Request
    ```
    # 8081 for running on host, 8080 otherwise
    curl -H "Accept: application/x-protobuf" "http://localhost:8080/league/D1/201617"
    ```

  - Protobuf Response  
    See ./proto/results.proto


## Monitoring

:football_results publishes metrics to Graphite via folsomite. To add new metrics extend the FootballResults.Metrics module. A Graphite Docker container is started in the "Running :football_results with HA" section or alternatively you can run "make start-graphite". Once started navigate to localhost:8082 and start exploring. Note it can take a minute or so for metrics to appear.
