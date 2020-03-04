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

## Tokens
```bash
vault create token
vault login s.VbR9cn2ermQAtut7ibZlV9Bc
vault token revoke s.VbR9cn2ermQAtut7ibZlV9Bc
```

## Auth methods
```bash
vault auth enable -path=github github
vault write auth/github/config organization=hashicorp
vault write auth/github/map/teams/my-team value=default,my-policy

vault list auth/github/map/teams
vault auth list

vault login -method=github
vault token revoke -mode path auth/github
vault auth disable github
```

## Vault server
```bash
vault operator init
vault operator unseal
vault login <root-token>
```