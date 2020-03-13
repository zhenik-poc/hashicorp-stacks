job "s3" {
  datacenters = ["dc1"]

  group "m-group" {
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
        port_map { web = 9000 }
      }
      env {
        MINIO_ACCESS_KEY = "minio"
        MINIO_SECRET_KEY = "minio123"
      }
      service {
        name = "minio"
        port = "web"
      }
      resources {
        network {
          mbits = 50
          port "web" {}
        }
      }
    }
  }
}