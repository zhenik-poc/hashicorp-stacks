job "router" {
  datacenters = ["dc1"]
  type        = "service"

  constraint {
    attribute = "${attr.kernel.name}"
    value     = "linux"
  }

  group "traefik" {
    network {
      mode = "bridge"
      mbits = 5
      port "dashboard" {
        # traefik dashboard by default
        to = 8080
      }
      port "minio" {
        # some-entry point
        to = 3000
      }
    }
    service {
      name = "traefik-dashboard"
      tags = ["traefik-dashboard", "traefik", "dashboard", "http"]
      port = "dashboard"
      check {
        type     = "http"
        path     = "/dashboard"
        interval = "5s"
        timeout  = "2s"
      }
    }
    service {
      name = "traefik-minio"
      tags = ["traefik-minio", "traefik-s3", "traefik", "http"]
      port     = "minio"
      check {
        type     = "http"
        path     = "/minio/health/live"
        interval = "5s"
        port     = "minio"
        timeout  = "2s"
      }
    }
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
          - url: "http://{{range service "minio-dashboard"}}{{.Address}}:{{.Port}}{{end}}"
EOF
      }
      config {
        image = "traefik:v2.1.4"
        volumes = [
          "local/traefik.yml:/etc/traefik/traefik.yml",
          "local/rules.yml:/config/rules.yml"
        ]
      }
    }
  }
}