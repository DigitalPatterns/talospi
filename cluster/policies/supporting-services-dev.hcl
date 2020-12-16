path "secret/data/talos-support/dev" {
  capabilities = [ "read" ]
}
path "secret/data/talos-support" {
  capabilities = [ "read" , "list"]
}
path "secret/data/config-server/dev" {
  capabilities = [ "read" , "list"]
}
path "secret/data/config-server" {
  capabilities = [ "read" , "list"]
}
