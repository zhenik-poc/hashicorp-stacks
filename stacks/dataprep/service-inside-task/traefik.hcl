job "router" {
  datacenters = ["dc1"]
  type        = "service"

  constraint {
    attribute = "${attr.kernel.name}"
    value     = "linux"
  }

  group "traefik" {
    task "traefik" {
      driver = "docker"
      template {
        destination     = "/local/traefik.yml"
        data            = <<EOF
global:
  sendAnonymousUsage: false
api:
  insecure: true
  dashboard: true
  debug: true
entryPoints:
  web:
    address: ":80"
  some-entry:
    address: ":3000"
providers:
  file:
    watch: true
    filename: /config/rules.yml
    debugLogGeneratedTemplate: true
EOF
      }
      template {
        destination   = "/local/rules.yml"
        data          = <<EOF
http:
  routers:
    router-to-minio:
      entryPoints:
        - "some-entry"
      service: "minio-service"
      rule: "PathPrefix(`/minio`)"
  services:
    minio-service:
      loadBalancer:
        servers:
          - url: "http://{{range service "minio-dashboard-internal"}}{{.Address}}:{{.Port}}{{end}}"
EOF
      }
      config {
        image = "traefik:v2.1.4"
        volumes = [
          "local/traefik.yml:/etc/traefik/traefik.yml",
          "local/rules.yml:/config/rules.yml"
        ]
        port_map = {
          dashboard   = 8080
          apiMinio    = 3000
        }
      }
      service {
        name = "traefik-dashboard"
        tags = ["traefik-dashboard-tag"]
        port     = "dashboard"
        check {
          type     = "http"
          path     = "/dashboard"
          interval = "5s"
          timeout  = "2s"
        }
      }
      resources {
        cpu = 100
        memory = 256
        network {
          mbits = 1
          port "dashboard" {}
          port "apiMinio" {}
        }
      }
    }
  }
}