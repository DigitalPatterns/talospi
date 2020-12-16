path "secret/data/talos-engine/dev" {
  capabilities = [ "read" ]
}
path "secret/data/talos-engine" {
  capabilities = [ "read" , "list"]
}
path "secret/data/config-server/dev" {
  capabilities = [ "read" , "list"]
}
path "secret/data/config-server" {
  capabilities = [ "read" , "list"]
}
