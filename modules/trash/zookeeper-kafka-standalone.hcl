job "zookeeper" {

  datacenters = ["blue"]
  type = "service"

  group "zk" {
    count = 1
    restart {
      attempts = 2
      interval = "5m"
      delay    = "25s"
      mode     = "delay"
    }
    ephemeral_disk {
      migrate = true
      size    = "500"
      sticky  = true
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
        change_mode = "restart"
        splay = "1m"
        data = <<EOF
tickTime=2000
initLimit=5
syncLimit=2
standaloneEnabled=true
skipACL=true
4lw.commands.whitelist=*
zookeeper.datadir.autocreate=true
dataDir=/data
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
# zookeeper.log.dir=/zookeeper/log
zookeeper.log.dir=/logs
zookeeper.log.file=zookeeper.log
zookeeper.log.threshold=INFO
# zookeeper.tracelog.dir=/zookeeper/log
zookeeper.tracelog.dir=/logs
zookeeper.tracelog.file=zookeeper_trace.log
# ZooKeeper Logging Configuration
log4j.rootLogger=INFO, CONSOLE, ROLLINGFILE
# Log INFO level and above messages to the console
log4j.appender.CONSOLE=org.apache.log4j.ConsoleAppender
log4j.appender.CONSOLE.Threshold=INFO
log4j.appender.CONSOLE.layout=org.apache.log4j.PatternLayout
log4j.appender.CONSOLE.layout.ConversionPattern=%d{ISO8601} [myid:%X{myid}] - %-5p [%t:%C{1}@%L] - %m%n
# Add ROLLINGFILE to rootLogger to get log file output
log4j.appender.ROLLINGFILE=org.apache.log4j.RollingFileAppender
log4j.appender.ROLLINGFILE.Threshold=INFO
# log4j.appender.ROLLINGFILE.File=/zookeeper/log/zookeeper.log
log4j.appender.ROLLINGFILE.File=/logs/zookeeper.log
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
        hostname  = "zookeeper1"
        labels { group = "zk-docker" }
//        network_mode = "host"
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
      env { ZOO_LOG4J_PROP="INFO,CONSOLE" }
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
        port = "client"
        tags = [
          "zookeeper-client"
        ]
        check {
          type = "script"
          name = "status"
          command = "/bin/bash"
          args = ["-c", "/apache-zookeeper-3.5.5-bin/bin/zkServer.sh status"]
          interval = "25s"
          timeout  = "20s"
        }
        check {
          type = "script"
          name = "ruok"
          command = "/bin/bash"
          args = ["-c", "echo ruok | nc $NOMAD_IP_client $NOMAD_HOST_PORT_client"]
          interval = "25s"
          timeout  = "20s"
        }
        check {
          type = "script"
          name = "stat"
          command = "/bin/bash"
          args = ["-c", "echo stat | nc $NOMAD_IP_client $NOMAD_HOST_PORT_client"]
          interval = "25s"
          timeout  = "20s"
        }
      }
      service {
        port = "http"
        tags = [
          "zookeeper-client-http"
        ]
        check {
          type     = "http"
          name     = "http-available"
          port     = "http"
          path     = "/commands"
          interval = "5s"
          timeout  = "2s"
        }
      }
    }

    task "kafka-broker" {
      driver = "docker"
      //      setup by env variable actualy, but loger needs this file
      template {
        destination = "local/conf/brokerid"
        change_mode = "noop"
        data = <<EOF
{{ env "NOMAD_ALLOC_INDEX" | parseInt | add 1 }}
EOF
      }
      template {
        destination = "local/conf/log4j.properties"
        change_mode = "noop"
        data = <<EOF
# Define some default values that can be overridden by system properties
kafka.root.logger=INFO, CONSOLE, ROLLINGFILE
kafka.console.threshold=INFO
kafka.log.dir=/kafka/log
kafka.log.file=kafka.log
kafka.log.threshold=INFO
kafka.tracelog.dir=/kafka/log
kakfa.tracelog.file=kafka_trace.log

# Kafka Logging Configuration
log4j.rootLogger=INFO, CONSOLE, ROLLINGFILE

# Log INFO level and above messages to the console
log4j.appender.CONSOLE=org.apache.log4j.ConsoleAppender
log4j.appender.CONSOLE.Threshold=INFO
log4j.appender.CONSOLE.layout=org.apache.log4j.PatternLayout
log4j.appender.CONSOLE.layout.ConversionPattern=%d{ISO8601} [myid:%X{myid}] - %-5p [%t:%C{1}@%L] - %m%n

# Add ROLLINGFILE to rootLogger to get log file output
log4j.appender.ROLLINGFILE=org.apache.log4j.RollingFileAppender
log4j.appender.ROLLINGFILE.Threshold=INFO
log4j.appender.ROLLINGFILE.File=/kafka/log/kafka.log

# Max log file size of 10MB
log4j.appender.ROLLINGFILE.MaxFileSize=10MB
# uncomment the next line to limit number of backup files
log4j.appender.ROLLINGFILE.MaxBackupIndex=5
log4j.appender.ROLLINGFILE.layout=org.apache.log4j.PatternLayout
log4j.appender.ROLLINGFILE.layout.ConversionPattern=%d{ISO8601} [myid:%X{myid}] - %-5p [%t:%C{1}@%L] - %m%n
EOF
      }
      // dynamic env
//      template {
//        data = <<EOF
//# KAFKA_ZOOKEEPER_CONNECT = "{{range services}}{{if in .Tags "zookeeper-client"}}{{$services:=service .Name "passing"}}{{range $services}}{{if in .Tags "zookeeper-client"}}{{.Address}}:{{.Port}},{{end}}{{end}}{{end}}{{end}}"
//KAFKA_BROKER_ID = "{{ env "NOMAD_ALLOC_INDEX" | parseInt | add 1 }}"
//SLEEP_TIME = 40000
//EOF
//        destination = "secrets/file.env"
//        env = true
//      }
      config {
        image = "confluentinc/cp-kafka:5.3.1"
//        image     = "zhenik/sleep:2.0"
        hostname  = "kafka1"
        labels {
          group = "kafka-docker"
        }
//        network_mode = "host"
        port_map {
          kafka = 9092
        }
        volumes = [
          "local/data:/kafka"
        ]
        extra_hosts = [
          "${node.unique.name}:127.0.0.1"
        ]
      }
      resources {
        cpu = 100
        memory = 500
        network {
          mbits = 10
          port "kafka" {}
        }
      }
      env {
        //        KAFKA_BROKER_ID = "${KAFKA_BROKER_ID}"
        //        KAFKA_ADVERTISED_LISTENERS = "PLAINTEXT://${NOMAD_IP_kafka}:${NOMAD_HOST_PORT_kafka}"
        //        # example docker-compose file -> PLAINTEXT://kafka:9092,PLAINTEXT_HOST://localhost:29092
        //        KAFKA_ADVERTISED_LISTENERS = "PLAINTEXT://${NOMAD_IP_kafka}:${NOMAD_HOST_PORT_kafka},PLAINTEXT_HOST://${NOMAD_IP_kafka}:${KAFKA_BROKER_ID}${NOMAD_HOST_PORT_kafka}"
        //        KAFKA_LISTENER_PROTOCOL_MAP = "PLAINTEXT:PLAINTEXT,PLAINTEXT_HOST:PLAINTEXT"
//        KAFKA_ADVERTISED_LISTENERS = "PLAINTEXT://${NOMAD_IP_kafka}:${NOMAD_HOST_PORT_kafka}"
        KAFKA_ADVERTISED_LISTENERS = "LISTENER_DOCKER_INTERNAL://kafka1:19092,LISTENER_DOCKER_EXTERNAL://${NOMAD_IP_kafka}:${NOMAD_HOST_PORT_kafka}"
        KAFKA_LISTENER_PROTOCOL_MAP = "LISTENER_DOCKER_INTERNAL:PLAINTEXT,LISTENER_DOCKER_EXTERNAL:PLAINTEXT"
        KAFKA_INTER_BROKER_LISTENER_NAME = "LISTENER_DOCKER_INTERNAL"
        KAFKA_ZOOKEEPER_CONNECT = "${NOMAD_ADDR_zk1_client}"
        KAFKA_BROKER_ID = "1"
        SLEEP_TIME = 40000

        KAFKA_HEAP_OPTS = "-Xmx250m -Xms250m"
        KAFKA_LOG4J_OPTS = "-Dlog4j.configuration=file:/local/conf/log4j.properties"
        KAFKA_DATA_DIR = "/kafka"
      }
      service {
        port = "kafka"
        name = "kafka-broker"
        tags = [
          "kafka-broker"]
      }
    }
  }
}