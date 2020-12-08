path "pki_int/issue/svc-cluster-local" {
  capabilities = ["read", "list", "create", "update"]
}

path "pki_int/sign/svc-cluster-local" {
  capabilities = ["read", "list", "create", "update"]
}
