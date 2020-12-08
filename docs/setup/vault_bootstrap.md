# Bootstrap Vault on Kubernetes Cluster


Deploy the Vault helm chart (replace "TOKEN_HERE" with the consul token created for vault in the previous step into the chart)

```bash
kubectl create ns vault
helm -n vault install vault -f cluster/vault/bootstrap.yaml hashicorp/vault
```

When vault's deployed, it will not transition to a running state until it has been unlocked to do this follow these steps:


### Initialise Vault

1. Exec into the first vault pod
```bash
kubectl -n vault exec -it vault-0 -- sh
```

2. Run the vault initialisation command
```bash
/ $ vault operator init
```

That will return you a payload like:
```
Unseal Key 1: XXXUNSEALKEY1XXX
Unseal Key 2: XXXUNSEALKEY2XXX
Unseal Key 3: XXXUNSEALKEY3XXX
Unseal Key 4: XXXUNSEALKEY4XXX
Unseal Key 5: XXXUNSEALKEY5XXX

Initial Root Token: XXXROOT_TOKENXXX
```

These keys are sensitive and must be kept safe.


### Unlock Vault

You need to unlock each vault pod (This must be done on for every vault pod each time it restarts)

1. Exec into each vault pod [0..2]

```bash
kubectl -n vault exec -it vault-0 -- sh
```

2. Execute `unseal operator` command 3 times on each pod using a different unseal key from the output you got above each time

```bash
vault operator unseal
```

(you can use the same unlock keys on different pods but must use a different one each time for the same pod to complete the unlock sequence)

