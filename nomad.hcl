consul {
  token = "b6e29626-e23d-98b4-e19f-c71a96fbdef7"
  address = "127.0.0.1:8500"
}

advertise {
  http = "{{ GetInterfaceIP \"docker0\" }}"
  rpc  = "{{ GetInterfaceIP \"docker0\" }}"
  serf  = "{{ GetInterfaceIP \"docker0\" }}"
}

client {
  enabled = true
  network_interface = "docker0"
}
