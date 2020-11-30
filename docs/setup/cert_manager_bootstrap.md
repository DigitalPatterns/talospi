# Create Intermediate Certificate Issuing Authority

With this section we are going to create a signed Intermediate Root Certificate, after which we will use that to create 
a temporary TLS certificate for Vault. At this point we update vault to use this certificate. Once that step is completed
we install Cert-Manager. Lastly we update Vault to use Cert-Manager to get its certificate.

##### Note

Before starting this guide it is recommended that you have an offline RootCA built. 
This can be made also using the offline CA raspberry pi guide.


### Create Intermediate CA


#### Step 1 - Create a Intermediate CA CSR

Firstly export your VAULT_TOKEN, VAULT_ADDR for the TalosPi hosted vault, then port-forward a connection from your
local machine to the vault.

```bash
export VAULT_TOKEN="TOKEN"
export VAULT_ADDR="http://localhost:8200"
kubectl -n databases port-forward service/vault 8200:8200 &
```

The TOKEN is the Initial Root Token given when unsealing the Vault in the setup steps.


Create an intermediate PKI store and CSR for the cluster

```bash
vault secrets enable -path=pki_int pki
vault secrets tune -max-lease-ttl=43800h pki_int
vault write -format=json pki_int/intermediate/generate/internal \
        common_name="default.cluster.local  Talos Production Intermediate Authority" \
        | jq -r '.data.csr' > pki_intermediate.csr
```

The above command has left a Certificate Signing Request output into your current directory - `pki_intermediate.csr`


#### Step 2 - Sign the Intermediate CSR with the RootCA

Sign the certificate using the RootCA against the Vault stored on the Raspberry PI 
(ideally use a different terminal window for this next set of commands).
Please also note the change to use the RootCA Vaults Token / URL instead of the new K8s cluster. You may need to unseal 
the RootCA vault if was powered down.

```bash
export VAULT_ADDR="https://PI_IP_ADDRESS:8200"
export VAULT_TOKEN=PI_ROOT_TOKEN
vault write -tls-skip-verify -format=json pki_root/root/sign-intermediate csr=@pki_intermediate.csr \
        format=pem_bundle ttl="43800h" \
        | jq -r '.data.certificate' > pki_intermediate.cert.pem
```


#### Step 3 - Load the signed certificate back into K8s Vault

Upload the signed certificate back to the kubernetes cluster vault
(use the original terminal window again)

```bash
vault write pki_int/intermediate/set-signed certificate=@pki_intermediate.cert.pem
```


#### Step 4 - Create roles to allow certificate requests 

Create a role to allow one for Consul and one for Cert-Manager to be able to request certificates

```bash
vault write pki_int/roles/default-svc-cluster-local \
        allow_any_name=true \
        allow_bare_domains=true \
        allow_subdomains=true \
        allow_glob_domains=true \
        allow_localhost=true \
        allow_ip_sans=true \
        allowed_other_sans="*" \
        use_csr_common_name=true \
        use_csr_sans=true \
        require_cn=false \
        max_ttl="8760h"

```


#### Step 5 - Create Vault TLS certificate

Create Vault a TLS certificate valid for one year

```bash
VAULT_SKIP_VERIFY=true VAULT_FORMAT=json vault  write pki_int/issue/default-svc-cluster-local common_name="vault.databases.svc.cluster.local" ttl="8760h" > vault_cert.json
```

jq -r '.data.private_key' < vault_cert.json > tls.key
jq -r '.data.certificate' < vault_cert.json > tls.crt
jq -r '.data.issuing_ca' < vault_cert.json > ca.crt

Then append the RootCA *ca.crt* to the ca.crt, afterwards append ca.crt to tls.crt.

```bash
cat RootCA.crt >> tls.crt
cat ca.crt >> tls.crt
```


#### Step 6 - Upgrade Vault to service via TLS

Create a kubernetes secret that includes the ca with the tls cert and key.

```bash
kubectl -n databases create secret generic vault-default-cert --from-file=./tls.crt --from-file=./tls.key --from-file=./ca.crt
```

```bash
helm -n databases upgrade vault -f cluster/vault/tls.yaml hashicorp/vault
kubectl -n databases delete pod vault-0 vault-1 vault-2
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

```bash
kubectl -n databases port-forward service/vault 8200:8200 &
```

```bash
export VAULT_ADDR="https://127.0.0.1:8200"
```


#### Step 7 - Setup Cert-Manager

Create a policy for cert-manager for Vault in a file called `/tmp/cert-manager.hcl`

```hcl
path "pki_int/issue/default-svc-cluster-local" {
  capabilities = ["read", "list", "create", "update"]
}

path "pki_int/sign/default-svc-cluster-local" {
  capabilities = ["read", "list", "create", "update"]
}
```

Upload the policy to Vault for Cert-manager to access Vault

```bash
vault policy write -tls-skip-verify default-svc-cluster-local /tmp/cert-manager.hcl
```

#### Step 8 - Install Cert-Manager

```bash
kubectl apply -f https://github.com/jetstack/cert-manager/releases/download/v1.1.0/cert-manager.yaml
```
[https://cert-manager.io/docs/installation/kubernetes/ Cert-Manager Docs](https://cert-manager.io/docs/installation/kubernetes/)



Create a kubernetes secret containing the token for cert-manager to access vault as *cert-manager-secret.yaml*

```bash
vault token create -tls-skip-verify -period=8760h -policy=default-svc-cluster-local -explicit-max-ttl=8760h
kubectl -n cert-manager create secret generic cert-manager-vault-token --from-literal=token=$TOKEN
```
$TOKEN is the token output from the first command.

Create the Issuer yaml for cert-manager as *vault-issuer.yaml*

```yaml
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: vault-issuer
spec:
  vault:
    path: pki_int/sign/default-svc-cluster-local
    server: https://vault.databases.svc.cluster.local:8200
    caBundle: <base64 encoded caBundle PEM file>
    auth:
      tokenSecretRef:
        name: cert-manager-vault-token
        key: token
```

Upload the secret and issuer to kubernetes

```bash
kubectl -n cert-manager create -f vault-issuer.yaml
```


#### Step 9 - Create a Vault cert from Vault issued by Cert-Manager

Create vault cert issued by cert-manager

```bash
kubectl -n databases create -f cluster/vault/cert.yaml
```

Check the certificate wss issued

```bash
kubectl -n databases get certificates | grep vault
```


#### Step 10 - Update Vault to use the Cert-Manager issued cert

Update the helm Vault config with the following to use the new TLS settings:
 

Restart Vault to use the new settings

```bash
helm -n databases upgrade vault -f cluster/vault/tls_2.yaml hashicorp/vault
kubectl -n databases delete pod vault-0 vault-1 vault-2
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
