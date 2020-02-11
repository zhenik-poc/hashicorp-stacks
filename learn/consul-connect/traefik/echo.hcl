job "echo" {
  datacenters = ["dc1"]
  type = "service"

  group "distributed" {
    count = 3
    network {
      mode = "bridge"
    }
    service {
      name = "test-api"
      port = 3000
      connect {
        sidecar_service {}
      }
    }
    task "web" {
      driver = "docker"

      config {
        image = "zhenik/uuid:2.0"
      }
    }
  }
}