job "kafka-zookeeper" {
  datacenters = ["dc1"]
  type = "service"
  update {
    max_parallel = 1
  }

  group "standalone" {
    count = 1
    restart {
      attempts = 5
      interval = "5m"
      delay = "25s"
      mode = "delay"
    }
    ephemeral_disk {
      migrate = true
      size = "500"
      sticky = true
    }

    task "zk1" {
      driver = "docker"
      //ID
      template {
        destination = "local/data/myid"
        change_mode = "noop"
        data = <<EOF
1
EOF
      }
      //default config
      template {
        destination = "local/conf/zoo.cfg"
        change_mode = "noop"
        splay = "1m"
        data = <<EOF
tickTime=2000
initLimit=5
syncLimit=2
standaloneEnabled=true
reconfigEnabled=true
skipACL=true
zookeeper.datadir.autocreate=true
4lw.commands.whitelist=*
dataDir=/data
dynamicConfigFile=/conf/zoo.cfg.dynamic
EOF
      }
      //dynamic config
      template {
        destination = "local/conf/zoo.cfg.dynamic"
        change_mode = "noop"
        splay = "1m"
        data = <<EOF
server.1={{ env "NOMAD_IP_client" }}:{{ env "NOMAD_HOST_PORT_peer1" }}:{{ env "NOMAD_HOST_PORT_peer2" }};{{ env "NOMAD_HOST_PORT_client" }}
EOF
      }
      //logger appender
      template {
        destination = "local/conf/log4j.properties"
        change_mode = "noop"
        data = <<EOF
# Define some default values that can be overridden by system properties
zookeeper.root.logger=INFO, CONSOLE, ROLLINGFILE
zookeeper.console.threshold=INFO
zookeeper.log.dir=/zookeeper/log
zookeeper.log.file=zookeeper.log
zookeeper.log.threshold=INFO
zookeeper.tracelog.dir=/zookeeper/log
zookeeper.tracelog.file=zookeeper_trace.log

# ZooKeeper Logging Configuration
log4j.rootLogger=${zookeeper.root.logger}

# Log INFO level and above messages to the console
log4j.appender.CONSOLE=org.apache.log4j.ConsoleAppender
log4j.appender.CONSOLE.Threshold=${zookeeper.console.threshold}
log4j.appender.CONSOLE.layout=org.apache.log4j.PatternLayout
log4j.appender.CONSOLE.layout.ConversionPattern=%d{ISO8601} [myid:%X{myid}] - %-5p [%t:%C{1}@%L] - %m%n

# Add ROLLINGFILE to rootLogger to get log file output
log4j.appender.ROLLINGFILE=org.apache.log4j.RollingFileAppender
log4j.appender.ROLLINGFILE.Threshold=${zookeeper.log.threshold}
log4j.appender.ROLLINGFILE.File=${zookeeper.log.dir}/${zookeeper.log.file}

# Max log file size of 10MB
log4j.appender.ROLLINGFILE.MaxFileSize=10MB
# uncomment the next line to limit number of backup files
log4j.appender.ROLLINGFILE.MaxBackupIndex=5
log4j.appender.ROLLINGFILE.layout=org.apache.log4j.PatternLayout
log4j.appender.ROLLINGFILE.layout.ConversionPattern=%d{ISO8601} [myid:%X{myid}] - %-5p [%t:%C{1}@%L] - %m%n
EOF
      }
      config {
        image = "zookeeper:3.5.5"
        hostname = "zookeeper1"
        port_map {
          client = 2181
          peer1 = 2888
          peer2 = 3888
          http = 8080
        }
        volumes = [
          "local/conf:/conf",
          "local/data:/data",
          "local/logs:/logs"
        ]
      }
      env {
        ZOO_LOG4J_PROP = "INFO,CONSOLE"
      }
      resources {
        cpu = 100
        memory = 128
        network {
          mbits = 10
          port "client" {}
          port "peer1" {}
          port "peer2" {}
          port "http" {}
        }
      }
      service {
        port = "http"
        address_mode = "driver"
        tags = [
          "zookeeper-client-http"
        ]
        check {
          name = "check http service"
          type = "http"
          path = "/commands"
          interval = "10s"
          timeout = "2s"
        }
      }
      service {
        port = "client"
        address_mode = "driver"
        tags = [
          "zookeeper-client"
        ]
        check {
          type = "script"
          name = "status"
          command = "/bin/bash"
          args = [
            "-c",
            "/apache-zookeeper-3.5.5-bin/bin/zkServer.sh status"]
          interval = "25s"
          timeout = "20s"
        }
        check {
          type = "script"
          name = "ruok"
          command = "/bin/bash"
          args = [
            "-c",
            "echo ruok | nc $HOSTNAME $NOMAD_HOST_PORT_client"]
          interval = "25s"
          timeout = "20s"
        }
        check {
          type = "script"
          name = "stat"
          command = "/bin/bash"
          args = [
            "-c",
            "echo stat | nc $HOSTNAME $NOMAD_HOST_PORT_client"]
          interval = "25s"
          timeout = "20s"
        }
      }
    }
    task "ka1" {
      driver = "docker"
      config {
        hostname = "kafka1"
//        image = "confluentinc/cp-kafka:5.3.1"
//         DNS 172.17.0.1:53
        image = "zhenik/sleep:2.0"
        port_map {
          kafka = 9092
        }
      }

      env {
        SLEEP_TIME = 40000
        KAFKA_BROKER_ID = 1
        KAFKA_ZOOKEEPER_CONNECT = "${NOMAD_ADDR_zk1_client}"
        KAFKA_LISTENERS = "PLAINTEXT://${NOMAD_IP_kafka}:${NOMAD_HOST_PORT_kafka}"
        KAFKA_ADVERTISED_LISTENERS = "PLAINTEXT://${NOMAD_IP_kafka}:${NOMAD_HOST_PORT_kafka}"
        KAFKA_LISTENER_SECURITY_PROTOCOL_MAP = "PLAINTEXT:PLAINTEXT"
        KAFKA_LOG4J_LOGGERS = "kafka.controller=INFO,kafka.producer.async.DefaultEventHandler=INFO,state.change.logger=INFO"
        KAFKA_OFFSETS_TOPIC_REPLICATION_FACTOR = 1
      }
      resources {
        cpu = 1000
        memory = 2048
        network {
          port "kafka" {}
        }
      }
      service {
        port = "kafka"
        tags = [
          "kafka"
        ]
      }
    }
//    task "sr1" {
//      driver = "docker"
//      config {
//        image = "confluentinc/cp-schema-registry:5.3.1"
//        network_mode = "host"
//      }
//      env {
//        SCHEMA_REGISTRY_HOST_NAME = "${NOMAD_IP_http}"
//        SCHEMA_REGISTRY_LISTENERS = "http://${NOMAD_ADDR_http}"
//        SCHEMA_REGISTRY_KAFKASTORE_CONNECTION_URL = "${NOMAD_ADDR_zk1_client}"
//        SCHEMA_REGISTRY_KAFKASTORE_BOOTSTRAP_SERVERS = "PLAINTEXT://${NOMAD_ADDR_ka1_kafka}"
//      }
//      resources {
//        network {
//          port "http" {
//            static = 8081
//          }
//        }
//      }
//      service {
//        port = "http"
//        tags = [
//          "schema-registry"
//        ]
//        check {
//          name = "check http service"
//          type = "http"
//          path = "/subjects"
//          interval = "10s"
//          timeout = "2s"
//        }
//      }
//    }

  }
}
