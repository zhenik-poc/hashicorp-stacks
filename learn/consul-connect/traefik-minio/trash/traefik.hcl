job "k-router" {
//  datacenters = ["dc1"]
//  region = "public-blue"
  datacenters = ["blue"]
  type        = "service"

  group "traefik" {
    task "traefik" {
      driver = "docker"
      config {
        image = "traefik:v2.1.4"
        volumes = [
          "local/traefik.yml:/etc/traefik/traefik.yml",
          "local/minio.yml:/etc/traefik/minio.yml"
        ]
        port_map {
          dashboard = 8080
        }
      }

      template {
        destination     = "/local/traefik.yml"
        data            = <<EOF
entryPoints:
  http:
    address: ":8080"
  traefik:
    address: ":8081"
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
        destination   = "/local/minio.yml"
        data          = <<EOF
http:
  routers:
//    minio-router:
//      rule: Path(`/minio/test`)
//      service: minio-service
//      entryPoints:
//        - http

  middlewares:
    remove-path:
      replacePath:
        path: "/"

  services:
   minio-service:
      loadBalancer:
       servers:
         - url: "http://dataprep-plattform-blue.minio.service.blue.intern.minerva.loc:9000"
EOF
      }
      resources {
        cpu    = 100
        memory = 128
        network {
          port "dashboard" { }
//          port "api" { to = 8081 }
        }
      }

      service {
        name = "traefik"
        tags = [ "test-traefik",
          "fni-test",
          "fni-fni"]

        check {
          name     = "alive"
          type     = "tcp"
          port     = "dashboard"
          interval = "10s"
          timeout  = "2s"
        }
      }
    }
  }
}