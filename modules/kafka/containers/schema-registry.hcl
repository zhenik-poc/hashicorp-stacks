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
        image = "confluentinc/cp-schema-registry:5.4.0"
      }
      template {
        destination = "local/data/.envs"
        change_mode = "noop"
        env         = true
        data        = <<EOF
#HOSTNAME=127.0.0.1
SCHEMA_REGISTRY_HOST_NAME=schema-registry
SCHEMA_REGISTRY_LISTENERS="http://172.17.0.1:{{ env "NOMAD_HOST_PORT_http" }}"
SCHEMA_REGISTRY_KAFKASTORE_BOOTSTRAP_SERVERS="PLAINTEXT://172.17.0.1:29009"
EOF
      }
    }
    network {
      mode  = "bridge"
      mbits = 3
      # This exposes a port externaly
      port "http" {
        to = -1
      }
    }
  }
}
