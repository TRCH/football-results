nothing:

.SILENT:

build-app-image:
	docker build -t football-results:latest .

# single instance of app
start-app:
	docker run -p 8081:8081 -t football-results:latest

start-graphite:
	docker run -d --restart=always -p 8082:80 -p 2003-2004:2003-2004 -p 2023-2024:2023-2024 -p 8125:8125/udp -p 8126:8126 graphiteapp/graphite-statsd

# app with ha
create-docker-swarm:
	docker swarm init

start-app-ha:
	docker stack deploy --compose-file=docker-compose.yml prod

stop-app-ha:
	docker service rm prod_football-results prod_proxy prod_graphite

# troubleshooting
app-logs-ha:
	docker service logs prod_football-results

haproxy-logs-ha:
	docker service logs prod_proxy
