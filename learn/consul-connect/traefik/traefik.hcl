job "traefik" {
  datacenters = ["dc1"]
  type = "service"

  group "standalone" {
    count = 1
    network {
      mode ="bridge"

      # by specifying a port here in the network stanza, we're making the port
      # publically available
      port "http" {
        to = 8080
      }
      port "https" {
        to = 443
      }
      port "test" {
        to = 8888
      }

    }
    service {
      name = "dashboard"
      port = "http"
      check {
        type     = "http"
        path     = "/"
        interval = "30s"
        timeout  = "5s"
      }
    }
    service {
      name = "rest"
      port = "test"
    }

    service {
      connect {
        sidecar_service {
          proxy {
            upstreams {
              local_bind_port = 3000
              destination_name = "test-api"
            }
          }
        }
      }
    }

    task "node" {
      driver = "docker"

      config {
        image = "traefik:v2.0.4"
        volumes = [
          "local/traefik.yml:/etc/traefik/traefik.yml",
          "local/rules.yml:/config/rules.yml",
        ]
      }

      template {
        data = <<EOF
global:
  sendAnonymousUsage: false
api:
  insecure: true
  dashboard: true
  debug: true
entryPoints:
  web:
    address: ":80"
  websecure:
    address: ":443"
  test:
    address: ":8888"
providers:
  docker:
    exposedByDefault: false
  file:
    watch: true
    filename: /config/rules.yml
    debugLogGeneratedTemplate: true
EOF
        left_delimiter  = "{!"
        right_delimiter = "!}"
        destination     = "local/traefik.yml"
      }
      template {
        data = <<EOF
http:
  routers:
    router1:
      rule: Host(`localhost`)
      service: service1
      entryPoints:
        - web
    router2:
      rule: Host(`test.localhost`)
      service: service2
      entryPoints:
        - test
  services:
    service1:
      loadBalancer:
        servers:
          - url: http://httpbin.org
    service2:
      loadBalancer:
        servers:
          - url: http://localhost:3000
EOF
        left_delimiter  = "{!"
        right_delimiter = "!}"
        destination     = "local/rules.yml"
      }


    }
  }
}