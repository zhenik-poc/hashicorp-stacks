job "fail" {
  datacenters = ["dc1"]

  update {
    max_parallel      = 1
    health_check      = "checks"
    min_healthy_time  = "10s"
    healthy_deadline  = "5m"
    progress_deadline = "1m" // Specifies the deadline in which an allocation must be marked as healthy.
    auto_revert       = true
    auto_promote      = true
    canary            = 1
    stagger           = "30s"
  }

  group "group" {
    restart {
      attempts = 2
      delay    = "5s"
    }
    task "app1" {
      driver = "docker"

      config {
        image = "zhenik/json-server"
      }
      resources {
        network {
          port "http" {}
        }
      }
      service {
        port = "http"
        check {
          name = "will fail"
          type = "http"
          path = "/fail"
          interval = "10s"
          timeout = "2s"
        }
      }
    }
  }
}