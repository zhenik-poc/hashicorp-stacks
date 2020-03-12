job "schema-registry" {
  datacenters = ["dc1"]
  type        = "service"

  constraint {
    attribute = "${attr.kernel.name}"
    value     = "linux"
  }

  group "standalone" {
//    network {
//      mode  = "bridge"
//      mbits = 3
//      # This exposes a port externaly
//      port "http" {
//        to = -1
//      }
//      port "internal" {
//        to = 8081
//      }
//    }
    task "node" {
      driver = "docker"
      config {
        image = "confluentinc/cp-schema-registry:5.4.1"
        command = "bash"
        args = [
          "-c",
          // crutch: }===|==>---
          "echo HERE $HOSTNAME && export SCHEMA_REGISTRY_HOST_NAME=$HOSTNAME && /etc/confluent/docker/run"
        ]
        port_map {
          http = 8081
        }
      }
      template {
        destination = "local/data/.envs"
        change_mode = "noop"
        env         = true
        data        = <<EOF
SCHEMA_REGISTRY_LISTENERS="http://0.0.0.0:8081"
SCHEMA_REGISTRY_KAFKASTORE_BOOTSTRAP_SERVERS="PLAINTEXT://{{range service "kafka|any"}}{{.Address}}:{{.Port}}{{end}}"
EOF
      }
      resources {
        network {
          mode  = "bridge"
          mbits = 3
          port "http" {}
        }
      }
    }
  }
}
