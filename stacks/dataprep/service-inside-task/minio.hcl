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
        image = "minio/minio:RELEASE.2020-02-27T00-23-05Z"
        args = ["server", "/data",]
        port_map = {
          minio = 9000
        }
      }
      env {
        MINIO_ACCESS_KEY = "minio"
        MINIO_SECRET_KEY = "minio123"
      }
      service {
        name = "minio-dashboard-gateway"
        tags = ["s3", "minio", "gateway"]
        port = "minio"
      }
      service {
//        https://nomadproject.io/docs/job-specification/service/#inlinecode-address_mode-4
        address_mode = "driver"
        name = "minio-dashboard-internal"
        tags = ["s3", "minio", "internal"]
        port = "minio"
      }
      resources {
        cpu = 100
        memory = 256
        network {
          mbits = 5
          port "minio" {}
        }
      }
    }
  }
}