MAC_DOCKER := 192.168.0.190
LINUX_DOCKER := 172.17.0.1
HOST_DOCKER := ${LINUX_DOCKER}
NETWORK_INTERFACE_MAC := en0
NETWORK_INTERFACE_LINUX := docker0
NETWORK_INTERFACE := ${NETWORK_INTERFACE_LINUX}

X_TEST_ZOOKEEPER_JOB := ./modules/zookeeper/containers/zookeeper_unique_tasks.nomad
#X_TEST_ZOOKEEPER_JOB := ./modules/zookeeper/containers/zookeeper_bridge.nomad
#X_TEST_ZOOKEEPER_JOB := ./modules/zookeeper/containers/zookeeper_unique_tasks_bridge.nomad
X_TEST_ZOOKEEPER_JOB_NAME := zookeeper-cluster

X_TEST_KAFKA_JOB := ./modules/kafka/containers/kafka_1_broker.nomad
X_TEST_KAFKA_JOB_NAME := kafka-cluster


.PHONY: all
all:
.PHONY: exports
exports:
	export NOMAD_ADDR=http://${HOST_DOCKER}:4646

.PHONY: consul
consul:
	sudo consul agent -dev -client=${HOST_DOCKER} -dns-port=53

.PHONY: nomad
nomad:
	sudo nomad agent -dev-connect -bind=${HOST_DOCKER} -network-interface=${NETWORK_INTERFACE} -consul-address=${HOST_DOCKER}:8500

.PHONY: vault
vault:
	sudo vault server -dev --dev-listen-address=${HOST_DOCKER}:8200 -dev-root-token-id=root

# zookeeper
.PHONY: zoo-run
zoo-run:
	nomad run ${X_TEST_ZOOKEEPER_JOB}
.PHONY: zoo-stop
zoo-stop:
	nomad stop ${X_TEST_ZOOKEEPER_JOB_NAME}
.PHONY: zoo-status
zoo-status:
	nomad status ${X_TEST_ZOOKEEPER_JOB_NAME}

# kafka
.PHONY: kafka-run
kafka-run:
	nomad run ${X_TEST_KAFKA_JOB}
.PHONY: kafka-stop
kafka-stop:
	nomad stop ${X_TEST_KAFKA_JOB_NAME}
.PHONY: kafka-status
kafka-status:
	nomad status ${X_TEST_KAFKA_JOB_NAME}

