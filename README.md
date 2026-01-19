# Certificate Expiry

This Docker image checks the expiry date of given certificates and displays the results.

```
docker build -t certificate-expiry .
curl -o certificate.yaml https://raw.githubusercontent.com/tokenio/infra-config/refs/heads/master/kubernetes/kustomize/namespace-config/overlays/sandbox/external-ssl.yaml?token=$TOKEN
docker run -v $(pwd)/certificate.yaml:/app/certificate.yaml certificate-expiry
```
# cert-expiry
