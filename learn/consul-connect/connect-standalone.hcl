job "kafka-zookeeper" {
  datacenters = ["dc1"]
  type = "service"

  group "zookeeper" {
    network {
      mode = "bridge"
    }
    service {
      name = "prox-zookeeper"
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
        volumes = [
          "local/conf:/conf",
          "local/data:/data",
          "local/logs:/logs"
        ]
      }
    }
  }
}
