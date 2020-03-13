# HashiCorp stacks
Project for learning and testing HashiCorp products. 
Current focus are:
* HashiCorp consul 
* HashiCorp nomad 

## Prerequisites
1. Docker 
2. Binaries in $PATH:
    - [consul](https://www.consul.io/docs/install/index.html#precompiled-binaries)
    - [nomad](https://nomadproject.io/downloads/) 
    - [consul-template](https://releases.hashicorp.com/consul-template/)
    - [vault](https://www.vaultproject.io/downloads/)

## Setup consul+nomad cluster [linux only]

```bash
make consul
```
in separate terminal
```bash
make nomad
```

Consul ui available on [172.17.0.1:8500](http://172.17.0.1:8500)  
Nomad ui available on [172.17.0.1:4646](http://172.17.0.1:4646)  

## Project structure
| Directory        | Description           | 
| ------------- |:-------------| 
| learn      | experimenting: consul-connect, volumes, envoy filters | 
| modules      | nomad .hcl templates |   
| poc | proof of concepts with docker-compose     |   
| stacks | building stacks of technologies with nomad     |   