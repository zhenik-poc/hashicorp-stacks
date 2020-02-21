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
      }
      env {
        KAFKA_BROKER_ID = 1
        KAFKA_ZOOKEEPER_CONNECT = "localhost:2181"
        KAFKA_LOG4J_LOGGERS = "kafka.controller=DEBUG,kafka.producer.async.DefaultEventHandler=DEBUG,state.change.logger=DEBUG"
        KAFKA_LISTENERS = "PLAINTEXT://0.0.0.0:9092"
        KAFKA_ADVERTISED_LISTENERS = "PLAINTEXT://localhost:9092"
        KAFKA_LISTENER_SECURITY_PROTOCOL_MAP = "PLAINTEXT:PLAINTEXT"
        KAFKA_OFFSETS_TOPIC_REPLICATION_FACTOR = 1
      }
      resources {
        cpu    = 1000 # MHz
        memory = 1024 # MB // otherwise, Kafka will fail with - OOMKilled 137
      }
    }

    network {
      mode = "bridge"
    }

    service {
      port = 9092
      name = "kafka-bootstrap-server"
      connect {
        sidecar_service {
          proxy {
            upstreams {
              destination_name = "zookeeper-client"
              local_bind_port = 2181 // any open available port
            }
          }
        }
        // for debug purposes, rm for prod
        sidecar_task {
          driver = "docker"
          config {
            image = "${meta.connect.sidecar_image}"
            args  = [
              "-c",
              "${NOMAD_SECRETS_DIR}/envoy_bootstrap.json",
              "-l",
              "debug" // debug lvl
            ]
          }

          logs {
            max_files     = 2
            max_file_size = 2 # MB
          }

          resources {
            cpu    = 250 # MHz
            memory = 128 # MB
          }
          shutdown_delay = "5s"
        }
      }
    }
  }
}
