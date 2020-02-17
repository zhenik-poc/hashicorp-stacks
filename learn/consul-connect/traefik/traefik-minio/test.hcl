job "k39582-router" {
  datacenters = ["blue"]
  type        = "service"

  group "traefik" {
    count = 1

    task "traefik" {
      driver = "docker"

      config {
        image = "traefik:v2.1"

        volumes = [
          "local/traefik.yml:/etc/traefik/traefik.yml",
          "local/minio.yml:/etc/traefik/minio.yml"
        ]
      }
      resources {
        cpu    = 100
        memory = 128

        network {
          mbits = 10

          port "api" {
            static = 8080
          }

          port "dashboard" {
            static = 8081
          }
          port "minio" {
            static = 9000
          }
        }
      }

      template {
        data = <<EOF
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

        left_delimiter  = "{!"
        right_delimiter = "!}"
        destination     = "/local/traefik.yml"
      }
//      middlewares:
//      - remove-path
//      - minio-redirects
//      rule: "Path(`/minio-service`)"
      template {
        data = <<EOF
http:
  routers:
    router-to-minio:
      entryPoints:
        - "minio"
      service: "minio-service"
      middlewares:
        - minio-redirects
      rule: "Path(`/minio`)"
  middlewares:
    minio-redirects:
      replacePath:
        path: "/minio"
    testHeader:
      headers:
        accessControlAllowOrigin: "origin-list-or-null"
        accessControlMaxAge: 100
        addVaryHeader: true

  services:
    minio-service:
      loadBalancer:
        servers:
          - url: "http://dataprep-plattform-blue.minio.service.blue.intern.minerva.loc:9000"



EOF

        left_delimiter  = "{!"
        right_delimiter = "!}"
        destination = "/local/minio.yml"
      }

      service {
        name = "traefik"
        tags = [
          "test-traefik",
          "fni-test",
          "fni-fni"]

        check {
          name = "alive"
          type = "tcp"
          port = "api"
          interval = "10s"
          timeout = "2s"
        }


      }

    }
  }
}