# nomad/issues
job "queue" {
  region      = "global"
  datacenters = ["fra1"]
  type        = "service"

  update {
    stagger = "30s"
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
    task "zookeeper" {
      driver = "docker"
      config {
        hostname           = "zookeeper"
        image              = "zookeeper:3.5.5"
        dns_servers        = [ "${NOMAD_IP_zookeeper}", "172.17.0.1" ]
        dns_search_domains = [ "consul" ]
      }
      service {
        name = "zookeeper"
        tags = [ "zookeeper" ]
        port = "zookeeper"
        check {
          type = "tcp"
          path = "/"
          interval = "10s"
          timeout = "2s"
        }
      }
      env {
        MYID = 1
      }
      logs {
        max_files = 6
        max_file_size = 12
      }
      resources {
        cpu    = 250
        memory = 128

        network {
          mbits = 100
          port "zookeeper" {
            static = 2181
          }
        }
      }
    }
    task "kafka" {
      driver = "docker"
      config {
        hostname           = "kafka"
        image              = "wurstmeister/kafka"
        dns_servers        = ["${NOMAD_IP_kafka}"]
        dns_search_domains = ["consul"]
      }
      service {
        name = "kafka"
        tags = [ "kafka" ]
        port = "kafka"
        check {
          type = "tcp"
          path = "/"
          interval = "10s"
          timeout = "2s"
        }
      }
      env {
        KAFKA_ADVERTISED_HOST_NAME = "${NOMAD_IP_kafka}"
        KAFKA_ADVERTISED_PORT      = "${NOMAD_PORT_kafka}"
        KAFKA_ZOOKEEPER_CONNECT    = "${NOMAD_IP_kafka}:2181"
      }
      logs {
        max_files = 6
        max_file_size = 12
      }
      resources {
        cpu    = 1500
        memory = 2048

        network {
          mbits = 100
          port "kafka" {
            static = 9092
          }
        }
      }
    }
  }
}