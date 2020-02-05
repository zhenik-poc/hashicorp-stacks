job "zookeeper-kafka" {
  datacenters = ["dc1"]
  type = "service"

  constraint {
    attribute = "${attr.kernel.name}"
    value     = "linux"
  }

  group "zookeeper" {
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
zookeeper.log.dir=local/logs
zookeeper.log.file=zookeeper.log
zookeeper.log.threshold=INFO
zookeeper.tracelog.dir=local/logs
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
        //        volumes = [
        //          "local/conf:/conf",
        //          "local/data:/data",
        //          "local/logs:/logs"
        //        ]
      }
    }

    network {
      mode = "bridge"
      // admin panel 8080
      port "http" {
        to = 8080
      }
      port "client" {
        to = 2181
      }
      // all peer's ports should be also open https://stackoverflow.com/questions/30308727/zookeeper-keeps-getting-the-warn-caught-end-of-stream-exception
      port "peer1" {
        to = 2888
      }
      port "peer2" {
        to = 3888
      }
    }
    service {
      // expose admin panel
      name = "zookeeper-http"
      port = "http"
      check {
        type     = "http"
        path     = "/commands"
        interval = "30s"
        timeout  = "5s"
      }
    }
    service {
      // There are will be two services registered
      // `zoo` and `zoo-sidecar-proxy`
      name = "zoo"
      // make available communication for other containers to zookeeper via proxy
      port = "client" // port 2181
      connect {
        sidecar_service {}
      }
    }
  }
  group "kafka" {
    task "node" {
      driver = "docker"
      config {
        image = "confluentinc/cp-kafka:5.3.1"
        //        image = "zhenik/sleep:2.0"
      }
      env {
        SLEEP_TIME = 40000 // only for investigation with image => zhenik/sleep:2.0
        KAFKA_BROKER_ID = 1
        KAFKA_ZOOKEEPER_CONNECT = "${NOMAD_UPSTREAM_ADDR_zoo}"
        KAFKA_LOG4J_LOGGERS = "kafka.controller=INFO,kafka.producer.async.DefaultEventHandler=INFO,state.change.logger=INFO"
        KAFKA_LISTENERS = "PLAINTEXT://127.0.0.1:9092"
        KAFKA_ADVERTISED_LISTENERS = "PLAINTEXT://127.0.0.1:9092"
        KAFKA_LISTENER_SECURITY_PROTOCOL_MAP = "PLAINTEXT:PLAINTEXT"
      }
    }

    network {
      mode = "bridge"
      port "client" {
        to = 9092
      }
    }

    service {
      name = "kafka-bootstrapservers"
      port = "client"
      tags = [
        "kafka-bootstapservers"
      ]
      connect {
        sidecar_service {
          proxy {
            upstreams {
              destination_name = "zoo"
              local_bind_port = 9191
            }
          }
        }
      }
    }
  }
}
