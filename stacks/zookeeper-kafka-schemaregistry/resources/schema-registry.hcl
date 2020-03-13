job "schema-registry" {

  datacenters = ["dc1"]
  type        = "service"

  constraint {
    attribute = "${attr.kernel.name}"
    value     = "linux"
  }

  group "standalone" {
    task "node" {
      driver = "docker"
      config {
        image = "confluentinc/cp-schema-registry:5.4.1"
        port_map {
          http = 8081
        }
      }
      template {
        destination = "local/data/.envs"
        change_mode = "noop"
        env         = true
        data        = <<EOF
SCHEMA_REGISTRY_HOST_NAME=0.0.0.0
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
      service {
        name = "schema-registry"
        tags = ["schema-registry", "http"]
        port = "http"
        check {
          name      = "check schema-registry rest available"
          type      = "http"
          path      = "/subjects"
          interval  = "60s"
          timeout   = "4s"
        }
      }
    }
  }
}
