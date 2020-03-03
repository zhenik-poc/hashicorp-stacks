# General info
## Engines
Authentication
```bash
vault kv put secret/hello foo=world
vault kv put secret/hello foo=world excited=yes
vault kv get ssecret/hello
vault kv get secret/hello
```

## [Policies](https://learn.hashicorp.com/vault/getting-started/policies)

Authorization
```bash
vault policy write my-policy -<<EOF
# Dev servers have version 2 of KV secrets engine mounted by default, so will
# need these paths to grant permissions:
path "secret/data/*" {
  capabilities = ["create", "update"]
}

path "secret/data/foo" {
  capabilities = ["read"]
}
EOF
```

list
```bash
vault policy list
vault policy read my-policy
```