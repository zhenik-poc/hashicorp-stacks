# Alloc status
```bash
nomad status s3
nomad alloc status -stats 04d9627d

```
## Approaches
Without consul-connect
* `service-inside-group`: bridge network; file-provider; services registered in groups
* `service-inside-task`: host network; file-provider; services registered in tasks