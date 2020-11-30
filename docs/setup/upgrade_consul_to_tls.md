## Upgrade Consul to TLS

Consul acts as its own Intermediate Certificate Authority, as such we create a new Intermediate CA signed by our Talos 
K8s Intermediate CA for it to use.


#### Step 1 - Create Consul Intermediate CSR

Create an intermediate PKI store and CSR for the consul cluster

```bash
vault secrets enable -path=pki_int_consul pki
vault secrets tune -max-lease-ttl=43800h pki_int_consul
```

```bash
VAULT_FORMAT=json vault write pki_int_consul/intermediate/generate/exported \
    add_basic_constraints=true\
    common_name="cluster Talos Production Intermediate Authority" \
    format=pem \
    key_type=ec \
    key_bits=384 \
    >pki_consul_intermediate.json
jq -r '.data.private_key' < pki_consul_intermediate.json > pki_consul_intermediate.key.pem
jq -r '.data.csr' < pki_consul_intermediate.json > pki_consul_intermediate.csr
```


#### Step 2 - Sign the Consul CSR

```bash
vault write -tls-skip-verify -format=json pki_int/root/sign-intermediate \
        csr=@pki_consul_intermediate.csr \
        format=pem_bundle \
        ttl="43800h"
        | jq -r '.data.certificate' > pki_consul_intermediate.cert.pem
        
vault write -tls-skip-verify pki_int_consul/intermediate/set-signed certificate=@pki_consul_intermediate.cert.pem 
```


#### Step 3 - Update Consul to use TLS


```bash
kubectl -n databases create secret generic consul-ca-key --from-file='tls.key=./pki_consul_intermediate.key.pem'
kubectl -n databases create secret generic consul-ca-cert --from-file='tls.crt=./pki_consul_intermediate.cert.pem'
helm upgrade consul -f cluster/consul/tls.yaml hashicorp/consul
```


#### Step 4 - Update Vault to talk to Consul over TLS

Restart Vault to use the new settings

```bash
helm upgrade vault -f cluster/vault/tls_3.yaml hashicorp/vault
kubectl delete pod vault-0 vault-1 vault-2
```

As we restarted vault we will need to do the following:
* reset the port-forward to the kubernetes cluster
* update the VAULT_ADDR environment token now we are using TLS
* unseal the three vault instances

You need to unlock each vault pod (This must be done on for every vault pod each time it restarts)
Exec into each vault pod and execute unseal 3 times [0..2]

```bash
kubectl -n databases exec -it vault-0 -- sh
export VAULT_ADDR=https://127.0.0.1:8200
vault operator unseal -tls-skip-verify
```
