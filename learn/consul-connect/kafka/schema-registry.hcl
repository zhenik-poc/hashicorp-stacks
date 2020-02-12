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
        SCHEMA_REGISTRY_KAFKASTORE_BOOTSTRAP_SERVERS = "PLAINTEXT://${NOMAD_UPSTREAM_ADDR_kafka_bootstrap_server}"
        SCHEMA_REGISTRY_LISTENERS = "http://localhost:8081"
        SCHEMA_REGISTRY_HOST_NAME = "127.0.0.1"
//        SCHEMA_REGISTRY_KAFKASTORE_CONNECTION_URL = "${NOMAD_UPSTREAM_ADDR_zookeeper_client}"

        SCHEMA_REGISTRY_DEBUG = true
        SLEEP_TIME = 40000
      }

      config {
        image = "confluentinc/cp-schema-registry:5.3.1"
//        image = "zhenik/sleep:2.0"
//        extra_hosts = [
//          "127.0.0.1:schema-registry"
//        ]
//        args = [
//          "-c","export SCHEMA_REGISTRY_HOST_NAME=$HOSTNAME;/etc/confluent/docker/run"
//        ]
//        command = "sh"

//        command = "cat /etc/hosts"
      }


    }

    network {
      mode = "bridge"
    }

    service {
      name = "schema-registry"
      port = 8081
      connect {
        sidecar_service {
          proxy {
            upstreams {
              destination_name = "zookeeper-client"
              local_bind_port = 2181 // any open available port
            }
            upstreams {
              destination_name = "kafka-bootstrap-server"
              local_bind_port = 9092 // any open available port
            }
          }
        }
      }
    }
  }
}
