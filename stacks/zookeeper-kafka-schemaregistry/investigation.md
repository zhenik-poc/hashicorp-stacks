# Notes about issues running zookeeper+kafka+schema-registry
## My setup spec
//todo
## Related links schema-registry
1. [PR with a patch, but it is out-dated](https://github.com/confluentinc/schema-registry/pull/236) 
2. [Issue #199](https://github.com/confluentinc/schema-registry/issues/199)
3. [Solution with overriding container start command](https://github.com/confluentinc/schema-registry/issues/1126#issuecomment-537282929)

## Related links nomad
1. [Network stanza. Official doc](https://nomadproject.io/docs/job-specification/network/)
`NB! -> `Pay attention on placement differences  

2. [Runtime attributes](https://nomadproject.io/docs/runtime/interpolation/)
`NB! -> `Pay attention on `${attr.unique.network.ip-address}`  
3. [Stackoverflow: kafka-schema-registry-advertise-dynamic-port-in-container](https://stackoverflow.com/questions/58544545/kafka-schema-registry-advertise-dynamic-port-in-container)
4. [Service stanza. Official doc](https://nomadproject.io/docs/job-specification/service/#service-stanza)
`NB! -> `Pay attention on placement differences. It says
> Nomad 0.10 also allows specifying the service stanza at the task group level. This enables services in the same task group to opt into Consul Connect integration.

If you declare service at the group level for current job, it gives opportunity to other (at the same nomad client) containers communicate to 
it via nomad-client ip.

 