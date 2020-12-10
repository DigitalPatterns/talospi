path "secret/data/talos-reference-data-service/dev" {
  capabilities = [ "read" ]
}
path "secret/data/talos-reference-data-service" {
  capabilities = [ "read" , "list"]
}
path "secret/data/config-server/dev" {
  capabilities = [ "read" , "list"]
}
path "secret/data/config-server" {
  capabilities = [ "read" , "list"]
}
