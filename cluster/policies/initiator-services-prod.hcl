path "secret/data/talos-initiators/prod" {
  capabilities = [ "read" ]
}
path "secret/data/talos-initiators" {
  capabilities = [ "read" , "list"]
}
path "secret/data/config-server/prod" {
  capabilities = [ "read" , "list"]
}
path "secret/data/config-server" {
  capabilities = [ "read" , "list"]
}
