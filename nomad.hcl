client {
  enabled       = true
  network_speed = 10
  host_volume "mysql" {
    path      = "/opt/mysql/data"
    read_only = false
  }
}
