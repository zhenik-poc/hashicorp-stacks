job "s3" {
  datacenters = ["dc1"]

//  constraint {
//    attribute = "${node.class}"
//    value     = "node"
//  }

  group "minio" {
    ephemeral_disk {
      migrate = true
      size    = "500"
      sticky  = true
    }
    task "minio" {
      driver = "docker"
      config {
        image = "minio/minio:RELEASE.2020-01-03T19-12-21Z"
        volumes = ["local/data:/data",]
        args = ["server", "/data",]
        port_map { minio = 9000 }
      }
      env {
        MINIO_ACCESS_KEY = "minio"
        MINIO_SECRET_KEY = "minio123"
      }
      service {
        name = "minio"
//        tags = ["s3", "minio", "traefik.enable=true", "traefik.frontend.rule=Host:minio.10.244.234.64.ssli
        port = "minio"
        check {
          type     = "http"
          name     = "check_availability"
          path     = "/"
          port     = "minio"
          interval = "10s"
          timeout  = "2s"
        }
      }
      resources {
        network {
          mbits = 50
          port "minio" {
            to = 9000
          }
        }
      }
    }
  }
}