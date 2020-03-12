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
          "echo HERE $HOSTNAME && export SCHEMA_REGISTRY_HOST_NAME=$HOSTNAME && /etc/confluent/docker/run"
        ]
      }
//      template {
//        destination = "local/data/.envs"
//        change_mode = "noop"
//        env         = true
//        data        = <<EOF
//#HOSTNAME=172.17.0.1
//#SCHEMA_REGISTRY_HOST_NAME={{ env "NOMAD_IP_http" }}
//#SCHEMA_REGISTRY_HOST_NAME={{ env "HOSTNAME" }}
//#SCHEMA_REGISTRY_LISTENERS="http://172.17.0.1:{{ env "NOMAD_HOST_PORT_http" }},http://localhost:8081"
//#SCHEMA_REGISTRY_HOST_NAME=172.17.0.1
//#SCHEMA_REGISTRY_LISTENERS="http://{{ env "SCHEMA_REGISTRY_HOST_NAME" }}"
//SCHEMA_REGISTRY_LISTENERS="http://{{ env "NOMAD_ADDR_http" }}
//SCHEMA_REGISTRY_KAFKASTORE_BOOTSTRAP_SERVERS="PLAINTEXT://{{range service "kafka|any"}}{{.Address}}:{{.Port}}{{end}}"
//EOF
//      }
//      SCHEMA_REGISTRY_LISTENERS="http://localhost:8081,http://{{ env "NOMAD_ADDR_http" }}"
//  SCHEMA_REGISTRY_KAFKASTORE_BOOTSTRAP_SERVERS="PLAINTEXT://{{range service "kafka|any"}}{{.Address}}:{{.Port}}{{end}}"
      template {
        destination = "local/data/.envs"
        change_mode = "noop"
        env         = true
        data        = <<EOF
#SCHEMA_REGISTRY_LISTENERS="http://localhost:8081,http://{{ env "NOMAD_ADDR_http" }}"
SCHEMA_REGISTRY_LISTENERS="http://0.0.0.0:8081"
SCHEMA_REGISTRY_KAFKASTORE_BOOTSTRAP_SERVERS="PLAINTEXT://{{range service "kafka|any"}}{{.Address}}:{{.Port}}{{end}}"
EOF
      }
      resources {
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
  }
}
