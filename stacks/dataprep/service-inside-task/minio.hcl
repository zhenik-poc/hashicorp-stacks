job "s3" {
  datacenters = ["dc1"]
  type = "service"

  constraint {
    attribute = "${attr.kernel.name}"
    value     = "linux"
  }

  group "minio" {
    volume "minio-data" {
      type      = "host"
      read_only = false
      source    = "minio-host-volume"
    }
    task "minio" {
      driver = "docker"
      volume_mount {
        volume      = "minio-data"
        destination = "/data"
        read_only   = false
      }
      config {
        image     = "minio/minio:RELEASE.2020-02-27T00-23-05Z"
        args      = ["server", "/data",]
        port_map  = {
          dashboard = 9000
        }
      }
      env {
        MINIO_ACCESS_KEY = "minio"
        MINIO_SECRET_KEY = "minio123"
      }
      service {
        name = "minio-dashboard-gateway"
        tags = ["s3", "minio", "gateway"]
        port = "dashboard"
        # // https://docs.min.io/docs/minio-monitoring-guide.html
        check {
          name          = "check-minio-dashboard-available"
          type          = "http"
          path          = "/minio/health/live"
          port          = "dashboard"
          interval      = "10s"
          timeout       = "2s"
        }
      }
      service {
        address_mode  = "driver"
        name          = "minio-dashboard-internal"
        tags          = ["s3", "minio", "internal"]
        port          = "dashboard"
        check {
          name          = "check-minio-dashboard-available"
          type          = "http"
          path          = "/minio/health/live"
          port          = "dashboard"
          interval      = "10s"
          timeout       = "2s"
        }
      }
      resources {
        cpu     = 100
        memory  = 256
        network {
          mode  = "host"
          mbits = 5
          port "dashboard" {}
        }
      }
    }
  }
}