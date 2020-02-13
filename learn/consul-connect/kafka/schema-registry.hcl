job "schema-registry" {
  datacenters = ["dc1"]
  type = "service"

  constraint {
    attribute = "${attr.kernel.name}"
    value     = "linux"
  }

  group "standalone" {
    task "node" {
      driver = "docker"

      env {
        HOSTNAME = "localhost"
        SCHEMA_REGISTRY_HOST_NAME = "localhost"
        SCHEMA_REGISTRY_LISTENERS = "http://localhost:8081"
        SCHEMA_REGISTRY_KAFKASTORE_CONNECTION_URL = "localhost:2181"

        SLEEP_TIME = 40000
      }

      config {
        image = "confluentinc/cp-schema-registry:5.3.1"
//        image = "zhenik/sleep:2.0"
      }


    }

    network {
      mode = "bridge"
      # This exposes a port externaly
      port "http1" {
        to = -1
      }

      port "http2" {}
    }

    service {
      name = "sr"
      port = 8081
      connect {
        sidecar_service {
          proxy {
            upstreams {
              destination_name = "zookeeper-client"
              local_bind_port = 2181
            }
            upstreams {
              destination_name = "kafka-bootstrap-server"
              local_bind_port = 9092
            }
          }
        }
      }
    }
  }
}
