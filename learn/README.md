## Additional info

```bashl
export NOMAD_ADDR="http://172.17.0.1:4646"
export CONSUL_HTTP_ADDR="172.17.0.1:8500"
consul connect proxy -service=nikita -upstream=zoo:9191 -log-level=TRACE

consul connect proxy -service=proxy-to-zookeeper -upstream=zoo:2181 -log-level=TRACE
consul connect proxy -service=proxy-to-kafka -upstream=kafka-bootstrap-server:9092 -log-level=TRACE
```

