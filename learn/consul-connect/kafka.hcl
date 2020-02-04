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
        image = "confluentinc/cp-kafka:5.3.1"
//        image = "zhenik/sleep:2.0"
      }
      env {
        SLEEP_TIME = 40000 // only for investigation with image => zhenik/sleep:2.0
        KAFKA_BROKER_ID = 1
        KAFKA_ZOOKEEPER_CONNECT = "${NOMAD_UPSTREAM_ADDR_zoo}"
        KAFKA_LOG4J_LOGGERS = "kafka.controller=INFO,kafka.producer.async.DefaultEventHandler=INFO,state.change.logger=INFO"
        KAFKA_LISTENERS = "PLAINTEXT://127.0.0.1:9092"
        KAFKA_ADVERTISED_LISTENERS = "PLAINTEXT://127.0.0.1:9092"
        KAFKA_LISTENER_SECURITY_PROTOCOL_MAP = "PLAINTEXT:PLAINTEXT"
      }
    }

    network {
      mode = "bridge"
      port "client" {
        to = 9092
      }
    }

    service {
      name = "kafka-bootstrapservers"
      port = "client"
      tags = [
        "kafka-bootstapservers"
      ]
      connect {
        sidecar_service {
          proxy {
            upstreams {
              destination_name = "zoo"
              local_bind_port = 9191
            }
          }
        }
      }
    }
  }
}
