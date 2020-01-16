job "kafka-cluster" {
  datacenters = ["dc1"]
  type = "service"
  update {
    max_parallel = 1
  }
  # define group
  group "kafka-broker" {
    # define the number of times the tasks need to be executed
    count = 1
    restart {
      attempts = 10
      interval = "5m"
      delay = "25s"
      mode = "delay"
    }
    ephemeral_disk {
      migrate = true
      size = "500"
      sticky = true
    }
    task "kafka" {
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
log4j.rootLogger=${kafka.root.logger}

# Log INFO level and above messages to the console
log4j.appender.CONSOLE=org.apache.log4j.ConsoleAppender
log4j.appender.CONSOLE.Threshold=${kafka.console.threshold}
log4j.appender.CONSOLE.layout=org.apache.log4j.PatternLayout
log4j.appender.CONSOLE.layout.ConversionPattern=%d{ISO8601} [myid:%X{myid}] - %-5p [%t:%C{1}@%L] - %m%n

# Add ROLLINGFILE to rootLogger to get log file output
log4j.appender.ROLLINGFILE=org.apache.log4j.RollingFileAppender
log4j.appender.ROLLINGFILE.Threshold=${kafka.log.threshold}
log4j.appender.ROLLINGFILE.File=${kafka.log.dir}/${kafka.log.file}

# Max log file size of 10MB
log4j.appender.ROLLINGFILE.MaxFileSize=10MB
# uncomment the next line to limit number of backup files
log4j.appender.ROLLINGFILE.MaxBackupIndex=5
log4j.appender.ROLLINGFILE.layout=org.apache.log4j.PatternLayout
log4j.appender.ROLLINGFILE.layout.ConversionPattern=%d{ISO8601} [myid:%X{myid}] - %-5p [%t:%C{1}@%L] - %m%n
EOF
      }
      // dynamic env
      template {
        data = <<EOF
KAFKA_ZOOKEEPER_CONNECT = "{{range services}}{{if in .Tags "zookeeper-client"}}{{$services:=service .Name "passing"}}{{range $services}}{{if in .Tags "zookeeper-client"}}{{.Address}}:{{.Port}},{{end}}{{end}}{{end}}{{end}}"
KAFKA_BROKER_ID = "{{ env "NOMAD_ALLOC_INDEX" | parseInt | add 1 }}"
EOF
        destination = "secrets/file.env"
        env = true
      }
      config {
        image = "confluentinc/cp-kafka:5.3.1"
        labels {
          group = "kafka-docker"
        }
        network_mode = "host"
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
        KAFKA_ADVERTISED_LISTENERS = "PLAINTEXT://${NOMAD_IP_kafka}:${NOMAD_HOST_PORT_kafka}"
        KAFKA_LISTENER_PROTOCOL_MAP = "PLAINTEXT:PLAINTEXT,PLAINTEXT_HOST:PLAINTEXT"
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