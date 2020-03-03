client {
  enabled       = true
  network_speed = 10
  host_volume "mysql" {
    path      = "/opt/mysql/data"
    read_only = false
  }
  host_volume "minio-host-volume" {
    path      = "/opt/minio/data"
    read_only = false
  }
}
