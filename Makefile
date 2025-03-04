up:
	docker compose up -d

down:
	docker compose down

reset: down up

create-kafka-topics:
	docker exec -it kafka /opt/kafka/bin/kafka-topics.sh --create --topic transactions_raw --bootstrap-server kafka:9092 --partitions 3 --replication-factor 1 --if-not-exists
	docker exec -it kafka /opt/kafka/bin/kafka-topics.sh --create --topic transaction_scores --bootstrap-server kafka:9092 --partitions 3 --replication-factor 1 --if-not-exists
	docker exec -it kafka /opt/kafka/bin/kafka-topics.sh --list --bootstrap-server kafka:9092

deep-clean: down
	docker volume rm $(shell docker volume ls -q)
	docker network rm $(shell docker network ls -q)
	docker image rm $(shell docker image ls -q)
	docker system prune -a

setup-topics: up create-kafka-topics
