## Upgrade Consul to TLS

Consul acts as its own Intermediate Certificate Authority, as such we create a new Intermediate CA signed by our Talos 
K8s Intermediate CA for it to use.


#### Step 1 - Create Consul Intermediate CSR

Create an intermediate PKI store and CSR for the consul cluster

```bash
vault secrets enable -path=pki_int_consul -tls-skip-verify pki  
vault secrets tune -tls-skip-verify -max-lease-ttl=43800h pki_int_consul
```

```bash
VAULT_FORMAT=json vault write -tls-skip-verify pki_int_consul/intermediate/generate/exported \
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

Sign the certificate using the RootCA against the Vault stored on the Raspberry PI 
```bash
vault write -tls-skip-verify -format=json pki_root/root/sign-intermediate \
        csr=@pki_consul_intermediate.csr \
        format=pem_bundle \
        ttl="43800h" \
        | jq -r '.data.certificate' > pki_consul_intermediate.cert.pem
        
cat RootCA.crt >> pki_consul_intermediate.cert.pem
```

Upload back to the local root
```bash
vault write -tls-skip-verify pki_int_consul/intermediate/set-signed certificate=@pki_consul_intermediate.cert.pem 
```
Add the CA certs to the generated cert, this allows it to form a proper CA Chain in order to validate certificates.


#### Step 3 - Update Consul to use TLS


Ensure that *tls.yaml* and *tls_1.yaml* have the correct subject alternative name for you cluster.
e.g:

`serverAdditionalDNSSANs: ["consul-server.consul.svc.cluster.local"]`
 
Then upload the generated key and cert as Kube secrets, after which a Helm will perform a rolling restart.
```bash
kubectl -n consul create secret generic consul-ca-key --from-file='tls.key=./pki_consul_intermediate.key.pem'
kubectl -n consul create secret generic consul-ca-cert --from-file='tls.crt=./pki_consul_intermediate.cert.pem'
helm -n consul upgrade consul -f cluster/consul/tls.yaml hashicorp/consul
```

Once the cluster has healed and switched to using TLS, we run helm once more to switch consul to verify certificates.
```bash
helm -n consul upgrade consul -f cluster/consul/tls_1.yaml hashicorp/consul
```


You may find you need to kill the vault pods to force switching between stages.


#### Step 4 - Update Vault to talk to Consul over TLS

Restart Vault to use the new settings

```bash
helm -n vault upgrade vault -f cluster/vault/tls_3.yaml hashicorp/vault
kubectl -n vault delete pod vault-0 vault-1 vault-2
```

As we restarted vault we will need to do the following:
* reset the port-forward to the kubernetes cluster
* update the VAULT_ADDR environment token now we are using TLS
* unseal the three vault instances

You need to unlock each vault pod (This must be done on for every vault pod each time it restarts)
Exec into each vault pod and execute unseal 3 times [0..2]

```bash
kubectl -n vault exec -it vault-0 -- sh
export VAULT_ADDR=https://127.0.0.1:8200
vault operator unseal -tls-skip-verify
```
