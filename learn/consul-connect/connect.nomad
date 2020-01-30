job "countdash" {
  datacenters = ["dc1"]

  group "api" {
    network {
      mode = "bridge"
    }

    service {
      name = "count-api"
      port = "9001"

      connect {
        sidecar_service {}
      }
    }

    task "web" {
      driver = "docker"

      config {
        // https://hub.docker.com/layers/hashicorpnomad/counter-api/v1/images/sha256-f75b2e7204050e37f6aa969e40282f5dfe0b1e367660ecf65bbf3f71fc078f52
        image = "hashicorpnomad/counter-api:v1"
      }
    }
  }

  group "dashboard" {
    network {
      mode = "bridge"

      port "http" {
        static = 9002
        to     = 9002
      }
    }

    service {
      name = "count-dashboard"
      port = "9002"

      connect {
        sidecar_service {
          proxy {
            upstreams {
              destination_name = "count-api"
              local_bind_port  = 8080
            }
          }
        }
      }
    }

    task "dashboard" {
      driver = "docker"

      env {
        COUNTING_SERVICE_URL = "http://${NOMAD_UPSTREAM_ADDR_count_api}"
      }

      config {
        // https://hub.docker.com/layers/hashicorpnomad/counter-dashboard/v1/images/sha256-37124ddde971d9c377cc64e5a786aec4c0aa77c71d6604515a6968c81fd901ba
        image = "hashicorpnomad/counter-dashboard:v1"
      }
    }
  }
}