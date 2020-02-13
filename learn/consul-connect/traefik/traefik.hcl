job "traefik" {
  datacenters = ["dc1"]
  type        = "service"

  group "standalone" {
    service {
      name = "traefik-service"
      port = 8080
      tags = ["cgtag"]

      connect {
        sidecar_service {
          proxy {
            upstreams {
              destination_name  = "nginx-api"
              local_bind_port   = 80
            }
            upstreams {
              destination_name  = "uuid-api"
              local_bind_port   = 3000
            }
          }
        }
      }
    }
    network {
      mode = "bridge"
    }
    task "node" {
      driver = "docker"
      config {
        image = "traefik:v2.1"

        volumes = [
          "local/traefik.yml:/etc/traefik/traefik.yml",
          "local/rules.yml:/etc/traefik/rules.yml",
          "/var/run/docker.sock:/var/run/docker.sock"
        ]
      }

      // traefik.yml
      template {
        destination     = "local/traefik.yml"
        data            = <<EOF
entryPoints:
  http:
    address: ":8081"
  traefik:
    address: ":8080"
api:
  insecure: true
  dashboard: true
log:
  level: DEBUG
providers:
  file:
    filename: /etc/traefik/rules.yml
EOF
      }
      // rules.yml
      template {
        destination     = "local/rules.yml"
        data            = <<EOF
http:
  routers:
    nginx-router:
      rule: Path(`/nginx`)
      service: nginx-service
      middlewares:
        - remove-path
      entryPoints:
        - http
    uuid-router:
      rule: Path(`/uuid`)
      service: uuid-service
      middlewares:
        - remove-path
      entryPoints:
        - http

  middlewares:
    remove-path:
      replacePath:
        path: "/"

  services:
    nginx-service:
      loadBalancer:
        servers:
          - url: "http://{{ env "NOMAD_UPSTREAM_ADDR_nginx_api" }}"
    uuid-service:
      loadBalancer:
        servers:
          - url: "http://{{ env "NOMAD_UPSTREAM_ADDR_uuid_api" }}"
EOF
      }
    }
  }
}