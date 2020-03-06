job "s3" {
  datacenters = ["dc1"]
  type = "service"

  constraint {
    attribute = "${attr.kernel.name}"
    value     = "linux"
  }

  group "minio" {
    network {
      mode = "bridge"
      mbits = 5
      port "dashboard" {
        to = 9000
      }
    }
    service {
      name = "minio-dashboard"
      tags = ["minio", "dashboard", "http"]
      port = "dashboard"
      # // https://docs.min.io/docs/minio-monitoring-guide.html
      check {
        address_mode  = "driver"
        name          = "check-minio-dashboard-available"
        type          = "http"
        path          = "/minio/health/live"
        port          = "dashboard"
        interval      = "10s"
        timeout       = "2s"
      }
    }

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
        image = "minio/minio:RELEASE.2020-02-27T00-23-05Z"
        args = ["server", "/data",]
      }
      env {
        MINIO_ACCESS_KEY = "minio"
        MINIO_SECRET_KEY = "minio123"
      }
    }
  }
}