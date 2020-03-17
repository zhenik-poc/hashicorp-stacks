job "zookeeper" {
  datacenters = ["dc1"]
  type        = "service"

  constraint {
    attribute = "${attr.kernel.name}"
    value     = "linux"
  }

  group "standalone" {
    task "node" {
      driver = "docker"
      // full set of env for cp-zookeeper
      // https://github.com/confluentinc/cp-docker-images/blob/5.3.1-post/debian/zookeeper/include/etc/confluent/docker/zookeeper.properties.template
      template {
        destination     = "local/data/.envs"
        change_mode     = "noop"
        env             = true
        data            = <<EOF
HOSTNAME=0.0.0.0
ZOOKEEPER_SERVER_ID={{ env "NOMAD_ALLOC_INDEX" | parseInt | add 1 }}
ZOOKEEPER_CLIENT_PORT=2181
KAFKA_OPTS="-Dzookeeper.4lw.commands.whitelist=*"
ZOOKEEPER_SERVERS=0.0.0.0:2888:3888
ZOOKEEPER_TICK_TIME=2000
ZOOKEEPER_INIT_LIMIT=5
ZOOKEEPER_SYNC_LIMIT=2
ZOOKEEPER_MAX_CLIENT_CNXNS=60
ZOOKEEPER_JUTE_MAX_BUFFER=4000000
ZOOKEEPER_AUTOPURGE_SNAP_RETAIN_COUNT=10
ZOOKEEPER_AUTOPURGE_PURGE_INTERVAL=2
ZOOKEEPER_LOG4J_ROOT_LOGLEVEL=DEBUG
ZOOKEEPER_TOOLS_LOG4J_LOGLEVEL=DEBUG
EOF
      }
      config {
        image     = "confluentinc/cp-zookeeper:5.3.1"
        volumes   = [
          "local/data:/var/lib/zookeeper/data",
          "local/logs:/var/lib/zookeeper/log"
        ]
      }
    }

    network {
      mode = "bridge"
      mbits = 3
      port "peer1" {
        to = 2888
      }
      port "peer2" {
        to = 3888
      }
    }
    service {
      // There are will be two services registered
      // `zookeeper-client` and `zookeeper-client-sidecar-proxy`
      name = "zookeeper-client"
      // make available communication for other containers to zookeeper via proxy
      port = 2181
      connect {
        sidecar_service {
          proxy {
//            config {
//              envoy_public_listener_json = <<EOL
//          {
//            "@type": "type.googleapis.com/envoy.api.v2.Listener",
//            "name": "public_listener:0.0.0.0:21000",
//            "address": {
//              "socketAddress": {
//                "address": "0.0.0.0",
//                "portValue": 21000
//              }
//            },
//            "filterChains": [
//              {
//                "filters": [
//                  {
//                    "name": "envoy.http_connection_manager",
//                    "config": {
//                      "stat_prefix": "public_listener",
//                      "route_config": {
//                        "name": "local_route",
//                        "virtual_hosts": [
//                          {
//                            "name": "backend",
//                            "domains": ["*"],
//                            "routes": [
//                              {
//                                "match": {
//                                  "prefix": "/"
//                                },
//                                "route": {
//                                  "cluster": "local_app"
//                                }
//                              }
//                            ]
//                          }
//                        ]
//                      },
//                      "http_filters": [
//                        {
//                          "name": "envoy.router",
//                          "config": {}
//                        }
//                      ]
//                    }
//                  }
//                ]
//              }
//            ]
//          }
//          EOL
//            }
          }
        }
        sidecar_task {
          driver = "docker"
          config {
//            image = "${meta.connect.sidecar_image}"
            image = "envoyproxy/envoy:v1.13.0"
            args  = [
              "-c",
              "${NOMAD_SECRETS_DIR}/envoy_bootstrap.json",
              "-l",
              "debug"
            ]
          }

          logs {
            max_files     = 2
            max_file_size = 2 # MB
          }

          resources {
            cpu    = 250 # MHz
            memory = 128 # MB
          }
          shutdown_delay = "5s"
        }
      }
//      check {
//        type = "script"
//        name = "ruok"
//        command = "/bin/bash"
//        args = [
//          "-c",
//          "echo ruok | nc locahost $$ZOOKEEPER_CLIENT_PORT"]
//        interval = "25s"
//        timeout = "20s"
//      }
    }
  }
}
