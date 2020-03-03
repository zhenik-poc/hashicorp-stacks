# Volumes learn
## Nomad config
```hcl
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
```

## Verification
```bash
nomad node status -short -self
```

### Exports
```bash
export NOMAD_ADDR="http://172.17.0.1:4646"
export CONSUL_HTTP_ADDR="172.17.0.1:8500"
```

### Proxies local [debug]
To debug `minio_connect` create local proxy.
`NB!` when creating proxy, it should be port :9000 due to minio's redirects
```bash
consul connect proxy -service=proxy-to-minio -upstream=minio-client:9000 -log-level=TRACE
```