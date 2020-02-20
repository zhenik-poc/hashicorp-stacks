# [Issue 734](https://github.com/confluentinc/cp-docker-images/issues/734)
Only linux (maybe with mac if use `docker-machine`).
Specific of issue:
* each container stays behind envoy proxy
* containers are running on nomad client
* containers communicate via [`consul-connect`](https://learn.hashicorp.com/consul/getting-started/connect)
## Requirements
* Docker installed
* Binaries for `consul` and `nomad` in PATH

## Problem 
Schema registry is fail to start
```bash
[main] INFO org.apache.kafka.common.utils.AppInfoParser - Kafka version: 5.3.1-ccs
[main] INFO org.apache.kafka.common.utils.AppInfoParser - Kafka commitId: d7ac44734b9cf5cc
[main] INFO org.apache.kafka.common.utils.AppInfoParser - Kafka startTimeMs: 1582213293013
hostname: Name or service not known
Exception in thread "main" java.lang.ExceptionInInitializerError
	at io.confluent.kafka.schemaregistry.rest.SchemaRegistryMain.main(SchemaRegistryMain.java:40)
Caused by: org.apache.kafka.common.config.ConfigException: Invalid value java.net.UnknownHostException: 8951744fd77c: 8951744fd77c: Temporary failure in name resolution for configuration Unknown local hostname
	at io.confluent.kafka.schemaregistry.rest.SchemaRegistryConfig.getDefaultHost(SchemaRegistryConfig.java:525)
	at io.confluent.kafka.schemaregistry.rest.SchemaRegistryConfig.baseSchemaRegistryConfigDef(SchemaRegistryConfig.java:384)
	at io.confluent.kafka.schemaregistry.rest.SchemaRegistryConfig.<clinit>(SchemaRegistryConfig.java:339)
	... 1 more
```
## Steps to reproduce
1. Run consul, use makefile in repository root
```bash
make consul
```
2. Run nomad
```bash
make nomad
```
3. Run jobs for zookeeper, kafka and schema-registry
```bash
# first setup env
export NOMAD_ADDR=http://172.17.0.1:4646

nomad run ./learn/consul-connect/kafka/zookeeper.hcl
nomad run ./learn/consul-connect/kafka/kafka.hcl
nomad run ./learn/consul-connect/kafka/schema-registry.hcl
```

## Debugging
Nomad available on http://172.17.0.1:4646  
Consul available on http://172.17.0.1:8500  

There is opportunity to create local proxy to be able to connect to zookeeper or kafka.
```bash
# first setup env
export CONSUL_HTTP_ADDR="172.17.0.1:8500"

# consul connect proxy -service=<name> -upstream=<proxy-name-in-nomad-job>:<local port bound to> -log-level=TRACE
consul connect proxy -service=zookeeper-local-proxy -upstream=zookeeper-client:2181 -log-level=TRACE
consul connect proxy -service=kafka-bootrapservers-local-proxy -upstream=kafka-bootstrap-server:9092 -log-level=TRACE
```

Also all setup done on localhost.
All docker commands are available.

