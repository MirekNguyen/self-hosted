# Creating Kubernetes Secrets

This folder contains definitions for Kubernetes `Secret` resources used by various services. To apply them securely without committing sensitive data, create the secrets using the following `kubectl` commands.

## 1. Cloudflare API Key Secret (for `cert-manager`)

```sh
kubectl create secret generic cloudflare-api-key-secret \
  --namespace cert-manager \
  --from-literal=api-key='<your-cloudflare-api-key>'
```

## 2. Universal Auth Credentials (for `external-secrets`)

```sh
kubectl create secret generic universal-auth-credentials \
  --namespace external-secrets \
  --from-literal=clientId='<your-client-id>' \
  --from-literal=clientSecret='<your-client-secret>'
```

**Note:** Replace `<your-cloudflare-api-key>`, `<your-client-id>`, and `<your-client-secret>` with your actual secret values.
