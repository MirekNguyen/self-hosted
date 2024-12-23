# Self hosted

## Hashicorp vault installation

```bash
# Initialize hashicorp vault
kubectl exec -n vault -it vault-0 -- vault operator init

# Unsealing it so the cluster can access it
# Requires doing this command 3 times - and passing unseal keys
kubectl exec -n vault -it vault-0 -- vault operator unseal

# Pass vault token as secret
kubectl create secret generic vault-token \
  --namespace=external-secrets \
  --from-literal=token=...
```
