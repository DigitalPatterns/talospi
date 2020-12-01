# Talos Config Service

To ensure a consistent and secure approach to configuration for the Talos services we created a config service which 
uses Vault as its backend.

This is released as a private docker container, as such you need a docker registry secret within you namespace.

```bash
kubectl create secret docker-registry regcred --docker-server=https://index.docker.io/v1/ \
 --docker-username=<your-name> --docker-password=<your-pword> --docker-email=<your-email>
```


Create a policy in Vault for the configservice and apply the token given as a kubernetes secret.

```bash
kubectl -n databases port-forward service/vault 8200:8200 &
export VAULT_ADDR="https://127.0.0.1:8200"
vault policy write -tls-skip-verify config-server cluster/policies/config-server.hcl
vault token create -tls-skip-verify -period=8760h -policy=config-server -explicit-max-ttl=8760h
kubectl -n databases create secret generic config-server --from-literal=token=$TOKEN
```

Install the config service to the cluster

```bash
helm -n databases install configservice helm/configservice
```