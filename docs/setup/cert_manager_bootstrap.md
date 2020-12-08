# Create Intermediate Certificate Issuing Authority

With this section we are going to create a signed Intermediate Root Certificate, after which we will use that to create 
a temporary TLS certificate for Vault. At this point we update vault to use this certificate. Once that step is completed
we install Cert-Manager. Lastly we update Vault to use Cert-Manager to get its certificate.

##### Note

Before starting this guide it is recommended that you have an offline RootCA built. 
This can be made also using the offline CA raspberry pi guide.


## Create Intermediate Internal CA and Cert Manager Issuer


#### Step 1 - Create a Intermediate CA CSR

Firstly export your VAULT_TOKEN, VAULT_ADDR for the TalosPi hosted vault, then port-forward a connection from your
local machine to the vault.

```bash
export VAULT_TOKEN="TOKEN"
export VAULT_ADDR="http://localhost:8200"
kubectl -n vault port-forward service/vault 8200:8200 &
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
        | jq -r '.data.certificate' > ca-bundle.pem
```


#### Step 3 - Load the signed certificate back into K8s Vault

Upload the signed certificate back to the kubernetes cluster vault
(use the original terminal window again)

(first append the RootCA to the pem to create a chain)

```bash
cat ~/RootCa.crt >> ca-bundle.pem
vault write pki_int/intermediate/set-signed certificate=@ca-bundle.pem
```

Upload the RootCA Bundle as a secret to the namespace

```bash
kubectl -n vault create secret generic ca --from-file='ca-bundle.pem=./ca-bundle.pem'
```

#### Step 4 - Create roles to allow certificate requests 

Create a role to allow one for Consul and one for Cert-Manager to be able to request certificates

```bash
vault write pki_int/roles/svc-cluster-local \
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
VAULT_SKIP_VERIFY=true VAULT_FORMAT=json vault  write pki_int/issue/svc-cluster-local common_name="vault.vault.svc.cluster.local" ttl="8760h" > vault_cert.json
jq -r '.data.private_key' < vault_cert.json > tls.key
jq -r '.data.certificate' < vault_cert.json > tls.crt
jq -r '.data.issuing_ca' < vault_cert.json > ca.crt
```

Then append the RootCA *ca.crt* to the ca.crt, afterwards append ca.crt to tls.crt.

```bash
cat ca-bundle.pem >> tls.crt
```


#### Step 6 - Upgrade Vault to service via TLS

Create a kubernetes secret that includes the ca with the tls cert and key.

```bash
kubectl -n vault create secret generic vault-default-cert --from-file=./tls.crt --from-file=./tls.key --from-file='ca.crt=./ca-bundle.pem'
```

```bash
helm -n vault upgrade vault -f cluster/vault/tls.yaml hashicorp/vault
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


#### Step 7 - Install Cert-Manager

```bash
kubectl apply -f https://github.com/jetstack/cert-manager/releases/download/v1.1.0/cert-manager.yaml
```
[https://cert-manager.io/docs/installation/kubernetes/ Cert-Manager Docs](https://cert-manager.io/docs/installation/kubernetes/)



Create a policy in Vault for cert-manager and apply the token given as a kubernetes secret.

```bash
kubectl -n vault port-forward service/vault 8200:8200 &
export VAULT_ADDR="https://127.0.0.1:8200"
vault policy write -tls-skip-verify svc-cluster-local cluster/cert-manager/vault-policy.hcl
vault token create -tls-skip-verify -period=8760h -policy=svc-cluster-local -explicit-max-ttl=8760h
kubectl -n cert-manager create secret generic cert-manager-vault-token --from-literal=token=$TOKEN
```
$TOKEN is the token output from the first command.

Update **cluster/cert-manager/vault-issuer.yaml** putting in the base64 version of the ca bundle. 
`cat ca.crt | base64`

Create the Vault Cert issuer in kubernetes

```bash
kubectl create -f cluster/cert-manager/vault-issuer.yaml
```


#### Step 8 - Create a Vault cert from Vault issued by Cert-Manager

Create vault cert issued by cert-manager

```bash
kubectl -n vault create -f cluster/vault/cert.yaml
```

Check the certificate wss issued

```bash
kubectl -n vault get certificates | grep vault
```


#### Step 9 - Update Vault to use the Cert-Manager issued cert

Update the helm Vault config with the following to use the new TLS settings:
 

Restart Vault to use the new settings

```bash
helm -n vault upgrade vault -f cluster/vault/tls_2.yaml hashicorp/vault
kubectl -n vault delete pod vault-0 vault-1 vault-2
```

As we restarted vault we will need to do the following:
* reset the port-forward to the kubernetes cluster
* unseal the three vault instances

You need to unlock each vault pod (This must be done on for every vault pod each time it restarts)
Exec into each vault pod and execute unseal 3 times [0..2]

```bash
kubectl -n vault exec -it vault-0 -- sh
export VAULT_ADDR=https://127.0.0.1:8200
vault operator unseal -tls-skip-verify
```


## Create Intermediate Public CA & External Cert Manager Issuer


#### Step 1 - Create a Public Intermediate CA CSR

Firstly export your VAULT_TOKEN, VAULT_ADDR for the TalosPi hosted vault, then port-forward a connection from your
local machine to the vault.

```bash
export VAULT_TOKEN="TOKEN"
export VAULT_ADDR="https://localhost:8200"
kubectl -n vault port-forward service/vault 8200:8200 &
```

The TOKEN is the Initial Root Token given when unsealing the Vault in the setup steps.


Create an intermediate PKI store and CSR for the cluster

```bash
vault secrets enable -tls-skip-verify -path=pki_ext pki
vault secrets tune -tls-skip-verify -max-lease-ttl=43800h pki_ext
vault write -tls-skip-verify -format=json pki_ext/intermediate/generate/internal \
        common_name="pi.talos.rocks  Talos Rocks Intermediate Authority" \
        | jq -r '.data.csr' > pki_intermediate_ext.csr
```

The above command has left a Certificate Signing Request output into your current directory - `pki_intermediate_ext.csr`


#### Step 2 - Sign the Public Intermediate CSR with the RootCA

Sign the certificate using the RootCA against the Vault stored on the Raspberry PI 
(ideally use a different terminal window for this next set of commands).
Please also note the change to use the RootCA Vaults Token / URL instead of the new K8s cluster. You may need to unseal 
the RootCA vault if was powered down.

```bash
export VAULT_ADDR="https://PI_IP_ADDRESS:8200"
export VAULT_TOKEN=PI_ROOT_TOKEN
vault write -tls-skip-verify -format=json pki_root/root/sign-intermediate csr=@pki_intermediate_ext.csr \
        format=pem_bundle ttl="43800h" \
        | jq -r '.data.certificate' > ca-bundle-ext.pem
```


#### Step 3 - Load the signed public certificate back into K8s Vault

Upload the signed certificate back to the kubernetes cluster vault
(use the original terminal window again)

```bash
cat ~/RootCa.crt >> ca-bundle-ext.pem
vault write pki_ext/intermediate/set-signed certificate=@ca-bundle-ext.pem
```

Upload the RootCA Bundle as a secret to the namespace

```bash
kubectl -n keycloak create secret generic ca --from-file='ca-bundle.pem=./ca.crt'
```

#### Step 4 - Create roles to allow certificate requests 

Create a role to allow one for Consul and one for Cert-Manager to be able to request certificates

```bash
vault write pki_ext/roles/pi-talos-rocks \
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

#### Step 5 - Create Vault public issuer for Cert-Manager


Create a policy in Vault for cert-manager and apply the token given as a kubernetes secret.

```bash
vault policy write -tls-skip-verify pi-talos-rocks cluster/cert-manager/vault-policy-ext.hcl
vault token create -tls-skip-verify -period=8760h -policy=pi-talos-rocks -explicit-max-ttl=8760h
kubectl -n cert-manager create secret generic cert-manager-vault-token-ext --from-literal=token=$TOKEN
```
$TOKEN is the token output from the first command.

Update **cluster/cert-manager/vault-issuer-ext.yaml** putting in the base64 version of the ca bundle. 
`cat ca.crt | base64`

Create the Vault Cert issuer in kubernetes

```bash
kubectl create -f cluster/cert-manager/vault-issuer-ext.yaml
```
