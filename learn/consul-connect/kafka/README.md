## Additional info
### Exports

```bash
export NOMAD_ADDR="http://172.17.0.1:4646"
export CONSUL_HTTP_ADDR="172.17.0.1:8500"
```

### Proxies local
```bash
consul connect proxy -service=proxy-to-zookeeper -upstream=zookeeper-client:2181 -log-level=TRACE
consul connect proxy -service=proxy-to-kafka -upstream=kafka-bootstrap-server:9092 -log-level=TRACE
```

### Verify
#### Kafka local run
0. Export consul http address (my case local)
```bash
export CONSUL_HTTP_ADDR="172.17.0.1:8500"
```
1. create proxy to zookeeper. Pay attention that port 9191
```bash
consul connect proxy -service=proxy-to-zookeeper -upstream=zookeeper-client:9191 -log-level=TRACE
```
2. change `config/zookeeper.properties`, use proxy port 9191
```bash
zookeeper.connect=127.0.0.1:9191
```
3. run kafka [Getting started with kafka](https://kafka.apache.org/quickstart)
```bash
bin/kafka-server-start.sh config/server.properties
```

### Kafka nomad run
0. Export nomad and consul addresses
```bash
consul connect proxy -service=proxy-to-zookeeper -upstream=zookeeper-client:2181 -log-level=TRACE
consul connect proxy -service=proxy-to-kafka -upstream=kafka-bootstrap-server:9092 -log-level=TRACE
```

#### Kafka verify (apache)
* list topics 
```
bin/kafka-topics.sh --list --bootstrap-server localhost:9092
```
* create topic "test"  
```bash
bin/kafka-topics.sh --create --bootstrap-server localhost:9092 --replication-factor 1 --partitions 1 --topic test
```
* create console-producer
```bash
bin/kafka-console-producer.sh --broker-list localhost:9092 --topic test
```
* create console-consumer
```bash
bin/kafka-console-consumer.sh --bootstrap-server localhost:9092 --topic test --from-beginning
```

#### Kafka verify (confluent)
## Confluent Kafkacat
List kafka topics
```bash
docker run --tty \
           --network host \
           confluentinc/cp-kafkacat \
           kafkacat -b localhost:9092 \
                    -L
``` 

Consuming messages from a topic
```bash
docker run --tty \
           --network host \
           confluentinc/cp-kafkacat \
           kafkacat -b localhost:9092 -C -K: \
                    -f '\nKey (%K bytes): %k\t\nValue (%S bytes): %s\n\Partition: %p\tOffset: %o\n--\n' \
                    -t test2
```

### Schema registry issue 

> [SCHEMA_REGISTRY_HOST_NAME](https://docs.confluent.io/current/installation/docker/config-reference.html#required-schema-registry-settings)
>
> The hostname advertised in ZooKeeper.
> This is required if if you are running Schema Registry with multiple nodes. 
>Hostname is required because it defaults to the Java canonical hostname for the container, which may not always be resolvable in a Docker environment. 
>Hostname must be resolveable because secondary nodes serve registration requests indirectly by simply forwarding them to the current primary, 
>and returning the response supplied by the primary. For more information, see the Schema Registry documentation on Single Primary Architecture.


