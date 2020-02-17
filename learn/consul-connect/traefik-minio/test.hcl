job "k-router" {
  datacenters = ["blue"]
  type        = "service"
  group "traefik" {

    task "traefik" {
      driver = "docker"
      config {
        image   = "traefik:v2.1.4"
        volumes = [
          "local/traefik.yml:/etc/traefik/traefik.yml",
          "local/minio.yml:/etc/traefik/minio.yml"
        ]
        port_map {
          minio       = 9000
          ui          = 8081
        }
      }
      template {
        destination = "/local/traefik.yml"
        data        = <<EOF
entryPoints:
  http:
    address: ":8080"
  traefik:
    address: ":8081"
  minio:
    address: ":9000"
api:
  insecure: true
  dashboard: true
log:
  level: DEBUG
providers:
  file:
    filename: "/etc/traefik/minio.yml"
EOF
      }
      template {
        destination = "/local/minio.yml"
        data        = <<EOF
http:
  routers:
    router-to-minio:
      entryPoints:
        - "minio"
      service: "minio-service"
      rule: "PathPrefix(`/minio`)"
  services:
    minio-service:
      loadBalancer:
        servers:
          - url: "http://dataprep-plattform-blue.minio.service.blue.intern.minerva.loc:9000"
EOF
      }

      resources {
        cpu     = 100
        memory  = 128
        network {
          port "minio" {}
          port "ui" {}
        }
      }
    }
  }
}
