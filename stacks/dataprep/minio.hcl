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
      port "client" {
        to = 9000
      }
    }
    service {
      name = "minio-dashboard"
      tags = ["minio-dashboard-tag"]
      port = "client"
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