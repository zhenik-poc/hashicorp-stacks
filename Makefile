MAC_DOCKER := 192.168.0.190
LINUX_DOCKER := 172.17.0.1
HOST_DOCKER := ${LINUX_DOCKER}
NETWORK_INTERFACE_MAC := en0
NETWORK_INTERFACE_LINUX := docker0
NETWORK_INTERFACE := ${NETWORK_INTERFACE_LINUX}

X_TEST_ZOOKEEPER_JOB := ./learn/consul-connect/zookeeper.hcl
X_TEST_ZOOKEEPER_JOB_NAME := zookeeper

X_TEST_KAFKA_JOB := ./learn/consul-connect/kafka.hcl
X_TEST_KAFKA_JOB_NAME := kafka


.PHONY: all exports consul nomad vault zoo-run zoo-stop zoo-status kafka-run kafka-stop kafka-status kill
all:

exports:
	export NOMAD_ADDR=http://${HOST_DOCKER}:4646
	export CONSUL_HTTP_ADDR=http://${HOST_DOCKER}:8500
	export VAULT_ADDR=http://${HOST_DOCKER}:8200
	export VAULT_DEV_ROOT_TOKEN_ID=root
# `consul agent -dev` enabled connect integration
consul: exports
	sudo consul agent -dev -client=${HOST_DOCKER} -dns-port=53

nomad: exports
	sudo nomad agent -dev-connect \
		-bind=${HOST_DOCKER} \
		-network-interface=${NETWORK_INTERFACE} \
		-consul-address=${HOST_DOCKER}:8500 \
		-config=./nomad.hcl

vault: exports
	sudo vault server -dev \
		-dev-listen-address=${HOST_DOCKER}:8200 \
		-dev-root-token-id="root"
#		-dev-root-token-id=root \

kill: exports
	sudo pkill -f consul | true
	sudo pkill -f nomad | true

# zookeeper
zoo-run:
	nomad run ${X_TEST_ZOOKEEPER_JOB}
zoo-stop:
	nomad stop ${X_TEST_ZOOKEEPER_JOB_NAME}
zoo-status:
	nomad status ${X_TEST_ZOOKEEPER_JOB_NAME}

# kafka
kafka-run:
	nomad run ${X_TEST_KAFKA_JOB}
kafka-stop:
	nomad stop ${X_TEST_KAFKA_JOB_NAME}
kafka-status:
	nomad status ${X_TEST_KAFKA_JOB_NAME}

