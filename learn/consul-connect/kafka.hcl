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
        SLEEP_TIME = 40000
        KAFKA_BROKER_ID = 1
        KAFKA_ZOOKEEPER_CONNECT = "${NOMAD_UPSTREAM_ADDR_zookeeper_api}"
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
    # we're defining this service to advertise the urlprefix tag so that fabio
    # can then act as a proxy for our count-dashboard service
    service {
      name = "kafka-bootstrapservers"

      # use the dynamic port provided via the group.network.port stanza above
      port = "client"

      # tell fabio about this service so that it can proxy to the correct host and port
      tags = [
        "urlprefix-countdash.west.example.com/",
        "kafka-bootstapservers"
      ]
    }

    service {
      tags = [
        "kafka-bootstapservers"
      ]
      connect {
        sidecar_service {
          proxy {
            protocol = "tcp"
            upstreams {
              local_bind_port = 2181
              destination_name = "zookeeper-api"
            }
          }
        }
      }
    }

  }
}
