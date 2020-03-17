# Notes
## Start local proxy
```bash
export CONSUL_HTTP_ADDR=http://172.17.0.1:8500 && \
    consul connect proxy -service=its-a-local-proxy-name-whatever -upstream=zookeeper:2181 -log-level=TRACE
```