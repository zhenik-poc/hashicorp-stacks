job "zookeeper" {
  datacenters = ["dc1"]
  type = "service"

  constraint {
    attribute = "${attr.kernel.name}"
    value     = "linux"
  }

  group "standalone" {
    task "node" {
      driver = "docker"
      //ID
      template {
        destination = "local/data/myid"
        change_mode = "noop"
        data = <<EOF
1
EOF
      }
      template {
        destination = "local/conf/zoo.cfg"
        change_mode = "noop"
        splay = "1m"
        data = <<EOF
tickTime=2000
initLimit=5
4lw.commands.whitelist=*
dataDir=/data
maxClientCnxns=60
clientPort=2181
server.1=127.0.0.1:2888:3888
EOF
      }
      config {
        image = "confluentinc/cp-zookeeper:5.3.1"
        volumes = [
          "local/conf:/conf",
          "local/data:/data",
          "local/logs:/logs"
        ]
      }
      env {
        ZOOKEEPER_CLIENT_PORT = 2181
        ZOOKEEPER_SERVER_ID = 1
        KAFKA_OPTS = "-Dzookeeper.4lw.commands.whitelist=*"
      }
    }

    network {
      mode = "bridge"
    }
    service {
      // There are will be two services registered
      // `zoo` and `zoo-sidecar-proxy`
      name = "zookeeper-client"
      // make available communication for other containers to zookeeper via proxy
      port = 2181
      connect {
        sidecar_service {}
        sidecar_task {
          driver = "docker"
          config {
            image = "${meta.connect.sidecar_image}"
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
    }
  }
}
