path "secret/data/talos-engine/prod" {
  capabilities = [ "read" ]
}
path "secret/data/talos-engine" {
  capabilities = [ "read" , "list"]
}
path "secret/data/config-server/prod" {
  capabilities = [ "read" , "list"]
}
path "secret/data/config-server" {
  capabilities = [ "read" , "list"]
}
