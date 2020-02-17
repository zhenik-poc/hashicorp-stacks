job "s3" {
  datacenters = ["dc1"]
  type = "service"

  constraint {
    attribute = "${attr.kernel.name}"
    value     = "linux"
  }

  group "minio" {
    task "minio" {
      driver = "docker"
      config {
        image = "minio/minio:RELEASE.2020-01-03T19-12-21Z"
        volumes = ["local/data:/data",]
        args = ["server", "/data",]
      }
      env {
        MINIO_ACCESS_KEY = "minio"
        MINIO_SECRET_KEY = "minio123"
      }
    }

    network {
      mode = "bridge"
    }

    service {
      name = "minio-client"
      # when creating proxy, it should be port :9000 due to minio's redirects
      port = 9000
      connect {
        sidecar_service {}
        sidecar_task {
          driver = "docker"
          config {
            image = "${meta.connect.sidecar_image}"
            args  = [
              "-c",
              "${NOMAD_SECRETS_DIR}/envoy_bootstrap.json",
              "-l",
              "debug"
            ]
          }

          logs {
            max_files     = 2
            max_file_size = 2 # MB
          }

          resources {
            cpu    = 250 # MHz
            memory = 128 # MB
          }
          shutdown_delay = "5s"
        }
      }
    }
  }
}