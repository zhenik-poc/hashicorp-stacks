# Readme
## How to run consul [linux only]
```bash
make consul
```
in separate terminal
```bash
source .env
make nomad
```

Consul ui available on [172.17.0.1:8500](http://172.17.0.1:8500)  
Nomad ui available on [172.17.0.1:4646](http://172.17.0.1:4646)  

## How to run job
Export nomad address
```bash
export NOMAD_ADDR=http://172.17.0.1:4646
```

Than execute a job, example
```bash
nomad run ./learn/consul-connect/zookeeper.hcl
nomad run ./learn/consul-connect/kafka.hcl
```
