path "secret/data/talos-support/prod" {
  capabilities = [ "read" ]
}
path "secret/data/talos-support" {
  capabilities = [ "read" , "list"]
}
path "secret/data/config-server/prod" {
  capabilities = [ "read" , "list"]
}
path "secret/data/config-server" {
  capabilities = [ "read" , "list"]
}
