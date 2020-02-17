job "uuid" {
  datacenters = ["dc1"]
  type = "service"

  group "distributed" {
    count = 3
    network {
      mode = "bridge"
    }
    service {
      name = "uuid-api"
      port = 3000
      connect {
        sidecar_service {}
      }
    }
    task "node" {
      driver = "docker"

      config {
        image = "zhenik/uuid:2.0"
      }
    }
  }
}