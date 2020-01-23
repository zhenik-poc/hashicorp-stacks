# nomad/issues
job "queue" {
  datacenters = ["dc1"]
  type = "service"

  update {
    max_parallel = 1
  }

  group "zookeeper-kafka" {
    count = 1
    restart {
      interval = "1m"
      attempts = 12
      delay = "3s"
      mode = "delay"
    }
    ephemeral_disk {
      migrate = true
      size    = "500"
      sticky  = true
    }
    task "zookeeper" {
      driver = "docker"

      template {
        destination = "local/conf/zoo.cfg"
        change_mode = "noop"
        splay = "1m"
        data = <<EOF
tickTime=2000
initLimit=5
syncLimit=2
standaloneEnabled=true
skipACL=true
zookeeper.datadir.autocreate=true
4lw.commands.whitelist=*
dataDir=/data
server.1=server.1={{ env "NOMAD_IP_zoo" }}:2888:3888
EOF
      }
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
        hostname           = "zookeeper"
        image              = "zookeeper:3.5.5"
        network_mode = "host"
//        port_map {
//          client = 2181
//          http = 8080
//        }
        volumes = [
          "local/conf:/conf",
          "local/data:/data",
          "local/logs:/logs"
        ]
      }
      resources {
        cpu    = 250
        memory = 128
        network {
          mbits = 100
          port "client" {
            static = 2181
          }
          port "http" {
            static = 8080
          }
        }
      }
      service {
        name = "zoo"
        tags = [ "zookeeper" ]
        port = "client"
      }
    }
    task "kafka" {
      driver = "docker"
      config {
        hostname           = "kafka"
        network_mode = "host"
//        image              = "wurstmeister/kafka"
//        image              = "confluentinc/cp-kafka:5.3.1"
        image              = "zhenik/sleep:2.0"
        dns_servers        = ["${NOMAD_IP_kafka}"]
        dns_search_domains = ["consul"]
      }

      env {
        KAFKA_ADVERTISED_HOST_NAME = "${NOMAD_IP_kafka}"
//        KAFKA_ADVERTISED_PORT      = "${NOMAD_PORT_kafka}"
        KAFKA_ZOOKEEPER_CONNECT    = "${NOMAD_IP_kafka}:2181"
        KAFKA_ADVERTISED_LISTENERS = "LISTENER_DOCKER_INTERNAL://${NOMAD_IP_kafka}:9092,LISTENER_DOCKER_EXTERNAL://${NOMAD_IP_kafka}:${NOMAD_HOST_PORT_kafka}"
        KAFKA_LISTENER_PROTOCOL_MAP = "LISTENER_DOCKER_INTERNAL:PLAINTEXT,LISTENER_DOCKER_EXTERNAL:PLAINTEXT"
        KAFKA_INTER_BROKER_LISTENER_NAME = "LISTENER_DOCKER_INTERNAL"
      }
      resources {
        cpu    = 1500
        memory = 2048

        network {
          mbits = 100
          port "kafka" {}
        }
      }
      service {
        name = "kafka"
        tags = [ "kafka" ]
        port = "kafka"
      }
    }
  }
}