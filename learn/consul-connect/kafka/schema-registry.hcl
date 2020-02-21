job "schema-registry" {
//  datacenters = ["dc1"]
  datacenters = ["blue"]
  type = "service"

  constraint {
    attribute = "${attr.kernel.name}"
    value     = "linux"
  }

  group "standalone" {
    task "node" {
      driver = "docker"
//      template {
//        destination     = "local/etc/hosts"
//        change_mode     = "noop"
//        data            = <<EOF
//127.0.0.1       {{ env "HOSTNAME" }} localhost
//
//# The following lines are desirable for IPv6 capable hosts
//::1     ip6-localhost ip6-loopback
//fe00::0 ip6-localnet
//ff00::0 ip6-mcastprefix
//ff02::1 ip6-allnodes
//ff02::2 ip6-allrouters
//EOF
//      }
      env {
        HOSTNAME = "127.0.0.1"
//        HOSTNAME = "whaaaaat"
//        SCHEMA_REGISTRY_HOST_NAME = "0.0.0.0"
//        SCHEMA_REGISTRY_LISTENERS = "http://localhost:8081"
//        SCHEMA_REGISTRY_KAFKASTORE_CONNECTION_URL = "localhost:2181"
        NODE_UNIQUE_ID = "${node.unique.id}"
        ATTR_UNIQUE_HOSTNAME = "${attr.unique.hostname}"
        ATTR_UNIQUE_NETWORK_IP = "${attr.unique.network.ip-address}"
        SCHEMA_REGISTRY_HOST_NAME = "localhost"
        SCHEMA_REGISTRY_LISTENERS = "http://localhost:8081" # default 8081
        SCHEMA_REGISTRY_KAFKASTORE_BOOTSTRAP_SERVERS = "PLAINTEXT://localhost:9092"

        SLEEP_TIME = 40000
      }

      config {
        image = "confluentinc/cp-schema-registry:5.3.1"
//        image = "zhenik/sleep:2.0"
//        volumes   = [
//          "local/etc/hosts:/etc/hosts",
//        ]
//        command = "cat /etc/hosts"
//        hostname = "sr"
      }
    }

    network {
      mode = "bridge"
      # This exposes a port externaly
      port "http" {
        to = 8081
      }
    }

    service {
      name = "sr"
//      port = 8081
      connect {
        sidecar_service {
          proxy {
//            upstreams {
//              destination_name = "zookeeper-client"
//              local_bind_port = 2181
//            }
//            # upstream only to kafka
            upstreams {
              destination_name = "kafka-bootstrap-server"
              local_bind_port = 9092
            }
          }
        }
      }
    }
  }
}
