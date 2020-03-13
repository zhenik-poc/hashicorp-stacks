TOKEN :=
VAULT_ADDRESS := 172.17.0.1:8200

.PHONY: check-engine
all:

check-engine:
	curl --header "X-Vault-Token: <TOKEN>" \
           <VAULT_ADDRESS>/v1/sys/mounts

