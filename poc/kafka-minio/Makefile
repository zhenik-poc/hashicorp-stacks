.PHONY: all
all: run-infrastructure wait kafka-create-topic minio-config-update

# sleep for 20 secs
# warm up containers
.PHONY: wait
wait:
	sleep 20

## infrastructure: zookeeper kafka minio-server
.PHONY: run-infrastructure
run-infrastructure:
	docker-compose up -d zookeeper kafka minio-server

## create kafka topic using decouple-kafka-broker
.PHONY: kafka-create-topic
kafka-create-topic:
	docker-compose up kafka-setup

## config update done via minio-client (mc)
.PHONY: minio-config-update
minio-config-update:
	docker-compose up mc

## run event-consumer
.PHONY: kafka-event-consumer-run
kafka-event-consumer-run:
	docker-compose up event-consumer

## down all containers
.PHONY: down
down:
	docker-compose down