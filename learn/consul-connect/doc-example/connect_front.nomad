# https://github.com/hashicorp/nomad/issues/6733
# https://www.burgundywall.com/post/consul-connect
# https://www.burgundywall.com/post/nomad-sidecars
job "countdash-back" {
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


}