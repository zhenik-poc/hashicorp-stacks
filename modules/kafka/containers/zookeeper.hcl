job "zookeeper" {

  datacenters = ["dc1"]
  type = "service"

  group "z-group" {
    network {
      mode  = "bridge"
      mbits = 3
      port "client" {
        to = 2181
      }
    }
    service {
      name = "zookeeper"
      tags = ["zookeeper", "service-discovery", "tcp"]
      port = "client"
      check {
        name      = "check-zookeeper-available"
        type      = "tcp"
        interval  = "10s"
        timeout   = "2s"
      }
    }
    task "node" {
      driver = "docker"
      config {
        image   = "confluentinc/cp-zookeeper:5.4.1"
        volumes = [
          "local/lib:/var/lib/zookeeper",
          "local/logs:/var/log/zookeeper"
        ]
      }
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
    }
  }
}
