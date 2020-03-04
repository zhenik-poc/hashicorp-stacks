ui            = true

api_addr      = "http://172.17.0.1:8200"
cluster_addr  = "http://172.17.0.1:8201"

storage "consul" {
  address = "172.17.0.1:8500"
  path    = "vault/"
}

listener "tcp" {
  address     = "172.17.0.1:8200"
  tls_disable = 1
}