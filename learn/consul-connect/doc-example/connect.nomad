# https://github.com/hashicorp/nomad/issues/6733
# https://www.burgundywall.com/post/consul-connect
# https://www.burgundywall.com/post/nomad-sidecars
job "countdash" {
  datacenters = ["dc1"]

  group "api" {
    network {
      mode = "bridge"
    }

    service {
      # create a service so that it's added to the consul catalog. This will
      # allow us to create envoy proxies that serve up this service
      name = "count-api"

      # counter-api is listening on this port on it's docker assigned ip address
      # however it is not exposed anywhere on the host (eg. netstat). The
      # created sidecar proxies to this port
      port = "9001"

      # creates a service in catalog called count-api-sidecar-proxy. In
      # the lookups below, it's "publicly" listening on 29393 via nat
      # but it's not visible on the host via netstat
      connect {
        # start an envoy proxy sidecar for allowing incoming connections via consul connect
        sidecar_service {}
      }

      # dig +short srv count-api.service.consul
      # 1 1 9001 nomad1.node.west.consul.
      # dig +short srv count-api-sidecar-proxy.service.consul
      # 1 1 29393 nomad1.node.west.consul.
    }

    task "web" {
      driver = "docker"

      config {
        image = "hashicorpnomad/counter-api:v1"
      }
    }
  }

  group "dashboard" {
    network {
      mode ="bridge"

      # by specifying a port here in the network stanza, we're making the port
      # publically available
      port "http" {
        # static = 9002
        # by not specifying a static port, a dynamic one is allocated
        # the dynamic port is forwarded to 9002 in the container via iptables nat
        to = 9002
      }
    }

    # we're defining this service to advertise the urlprefix tag so that fabio
    # can then act as a proxy for our count-dashboard service
    service {
      name = "count-dashboard"

      # use the dynamic port provided via the group.network.port stanza above
      port = "http"

      # tell fabio about this service so that it can proxy to the correct host and port
      tags = [
        "urlprefix-countdash.west.example.com/",
      ]

      check {
        type     = "http"
        path     = "/"
        interval = "30s"
        timeout  = "5s"
      }
    }

    service {
      # in the online examples this was in the "count-dashboard" service but
      # that doesn't make sense to me as it's not a public service so shouldn't
      # be "exposed" on the port. Let's make a new service to "inject" the proxy
      # into the task so that the dashboard can communicate with the count-api
      # on port 8080. ie: count-dashboard connects to localhost:8080 and comes
      # out in count-api container and connects to port 9001
      connect {
        sidecar_service {
          proxy {
            upstreams {
              # create a proxy that listens on port 8080 in the dashboard container
              local_bind_port = 8080
              # the proxy then connects to service count-api
              destination_name = "count-api"
            }
          }
        }
      }
    }

    task "dashboard" {
      driver = "docker"

      env {
        COUNTING_SERVICE_URL = "http://${NOMAD_UPSTREAM_ADDR_count_api}"
      }

      config {
        image = "hashicorpnomad/counter-dashboard:v1"
      }
    } # task
  } # group
}