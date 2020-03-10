job "kafka" {
  datacenters = ["dc1"]
  type = "service"

  constraint {
    attribute = "${attr.kernel.name}"
    value     = "linux"
  }

  group "standalone" {
    task "node" {
      driver = "docker"
      config {
        image = "confluentinc/cp-kafka:5.4.0"
        volumes = [
          "local/data:/var/lib/kafka/data"
        ]
      }

      template {
        destination     = "local/data/.envs"
        change_mode     = "noop"
        env             = true
        data            = <<EOF
KAFKA_BROKER_ID={{ env "NOMAD_ALLOC_INDEX" | parseInt | add 1 }}
KAFKA_ZOOKEEPER_CONNECT={{range service "zookeeper|any"}}{{.Address}}:{{.Port}}{{end}}
KAFKA_LOG4J_LOGGERS="kafka.controller=DEBUG,kafka.producer.async.DefaultEventHandler=DEBUG,state.change.logger=DEBUG"
KAFKA_OFFSETS_TOPIC_REPLICATION_FACTOR=1
KAFKA_LISTENER_SECURITY_PROTOCOL_MAP=PLAINTEXT:PLAINTEXT,PLAINTEXT_HOST:PLAINTEXT
KAFKA_ADVERTISED_LISTENERS=PLAINTEXT://localhost:9092,PLAINTEXT_HOST://172.17.0.1:{{ env "NOMAD_HOST_PORT_external" }}
#KAFKA_OPTS="-Dcom.sun.management.jmxremote.authenticate=false -Dcom.sun.management.jmxremote.ssl=false -Dcom.sun.management.jmxremote.port=5555"
EOF
      }
      resources {
        cpu    = 200 # MHz
        memory = 1024 # MB // otherwise, Kafka will fail with - OOMKilled 137
        network {
          mode  = "bridge"
          mbits = 5
//          port "client" {
//            to = 9092
//          }
          // }===|==>---
          port "external" {
            to = -1
          }
        }
      }
    }

  }
}
