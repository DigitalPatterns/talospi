path "secret/data/talos-initiators/dev" {
  capabilities = [ "read" ]
}
path "secret/data/talos-initiators" {
  capabilities = [ "read" , "list"]
}
path "secret/data/config-server/dev" {
  capabilities = [ "read" , "list"]
}
path "secret/data/config-server" {
  capabilities = [ "read" , "list"]
}
