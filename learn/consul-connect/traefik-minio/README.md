## Additional info
### Exports

```bash
export NOMAD_ADDR="http://172.17.0.1:4646"
export CONSUL_HTTP_ADDR="172.17.0.1:8500"
```

### Proxies local
`NB!` when creating proxy, it should be port :9000 due to minio's redirects

```bash
consul connect proxy -service=proxy-to-minio -upstream=minio-client:9000 -log-level=TRACE
```