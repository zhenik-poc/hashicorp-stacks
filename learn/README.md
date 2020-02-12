# Consul-connect experiments
## Why consul connect
>I. Compare with `host` network
- everything deployed to 1 host, manual setup communication across nomad clients
- port collisions (or manual config changes), anyway you should know which ports are already busy
- no isolation [in and out] (nomad client become one big container)

>II. Compare with `bridge` network
- bridge network coupled with docker host, everything deployed to 1 host, manual setup communication across nomad clients (example: via overlay networks) 
- no isolation [in] (communication to containers are available via container IP address assigned by docker hos

> III. Consul connect
- transparent deployments to different nomad clients and support for communication across different nomad clients
- sidecars or native (`make research`)
- encryption in transit
- intentions (communication policy control)
- full isolation for container (has own issues), communication only via proxy

