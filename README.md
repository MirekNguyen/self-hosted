# Self hosted

## Create new certificate

- create a secret to issue (from Cloudflare API)

```bash
kubectl create secret generic cloudflare-api-key-secret \
  --namespace cert-manager \
  --type=Opaque \
  --from-literal=api-key=...
```

- issue new certificate

```bash
kubectl apply -f - <<EOF
apiVersion: cert-manager.io/v1
kind: Certificate
metadata:
  name: ssl-certificate
  namespace: default
spec:
  secretName: ssl-certificate
  issuerRef:
    name: acme-issuer
    kind: ClusterIssuer
  dnsNames:
    - '*.mirekng.com'
    - 'mirekng.com'
EOF
```

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
