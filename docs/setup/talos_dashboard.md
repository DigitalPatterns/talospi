
```bash
helm -n databases install presto helm/prestosql \
  --set presto.mongodb.credentials="camundaAdmin:<PASSWORD_HERE>@admin" \
  --set presto.service.issuerRefExt.name="letsencrypt" \
  --set presto.ingress.name="presto.dev.talos.cloud" \
  --set presto.ingress.class=traefik
```


#### Vault setup

Create a policy in Vault for the talosengine and apply the token given as a kubernetes secret. 
Replace *<VAULT_TOKEN>* with the root vault token. `export ENV=dev` Where the environment is 'Development (dev)' or 
'Production (prod)'. For other environments you will need to update the policy hcl file to match.

```bash
kubectl -n vault port-forward service/vault 8200:8200 &
export VAULT_ADDR="https://127.0.0.1:8200"
export VAULT_TOKEN="<VAULT_TOKEN>"
vault policy write -tls-skip-verify cubejs-backend cluster/policies/cubejs-backend-${ENV}.hcl
vault token create -tls-skip-verify -period=8760h -policy=cubejs-backend -explicit-max-ttl=8760h
kubectl create secret generic cubejsbackend --from-literal=token=$TOKEN
```



#### Deploy cubejs

```bash
 helm install cubejsbackend helm/cubejsbackend --set cubejsbackend.service.issuerRefExt.name=letsencrypt --set cubejsbackend.ingress.name="cubejsbackend.pi.talos.cloud" --set cubejsbackend.ingress.class=traefik
```
