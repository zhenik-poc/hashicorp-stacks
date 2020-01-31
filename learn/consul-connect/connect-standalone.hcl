job "kafka-zookeeper" {
  datacenters = ["dc1"]
  type = "service"

  group "zookeeper" {
    network {
      mode = "bridge"
      // expose admin panel
      port "http" {
        to = 8080
      }
    }
    service {
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
      name = "zookeeper-client-proxy"
      // make available communication for other containers to zookeeper via proxy
      port = "2181"
      connect {
        sidecar_service {}
      }
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
      template {
        destination = "local/conf/zoo.cfg"
        change_mode = "noop"
        splay = "1m"
        data = <<EOF
tickTime=2000
initLimit=5
4lw.commands.whitelist=*
dataDir=/data
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
        volumes = [
          "local/conf:/conf",
          "local/data:/data",
          "local/logs:/logs"
        ]
      }
    }
  }
  group "kafka" {
    network {
      mode ="bridge"
      port "client" {
        to = 9092
      }
    }
    service {
      name = "kafka-client"
      port = "client"
    }
    service {
      # in the online examples this was in the "count-dashboard" service but
      # that doesn't make sense to me as it's not a public service so shouldn't
      # be "exposed" on the port. Let's make a new service to "inject" the proxy
      # into the task so that the dashboard can communicate with the count-api
      # on port 8080. ie: count-dashboard connects to localhost:8080 and comes
      # out in count-api container and connects to port 9001
      connect {
        sidecar_service {
          proxy {
            upstreams {
              local_bind_port = 2181
              destination_name = "zookeeper-client-proxy"
            }
          }
        }
      }
    }

    task "ka1" {
      driver = "docker"
      config {
        image = "confluentinc/cp-kafka:5.3.1"
//        image = "zhenik/sleep:2.0"
      }
      env {
        SLEEP_TIME = 40000
        KAFKA_BROKER_ID = 1
        KAFKA_ZOOKEEPER_CONNECT = "${NOMAD_UPSTREAM_ADDR_zookeeper_client_proxy}"
        KAFKA_LOG4J_LOGGERS = "kafka.controller=INFO,kafka.producer.async.DefaultEventHandler=INFO,state.change.logger=INFO"
        KAFKA_LISTENERS = "PLAINTEXT://127.0.0.1:9092"
        KAFKA_ADVERTISED_LISTENERS = "PLAINTEXT://127.0.0.1:9092"
        KAFKA_LISTENER_SECURITY_PROTOCOL_MAP = "PLAINTEXT:PLAINTEXT"
      }
    }
  }
}
