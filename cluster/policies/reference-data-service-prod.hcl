path "secret/data/talos-reference-data-service/prod" {
  capabilities = [ "read" ]
}
path "secret/data/talos-reference-data-service" {
  capabilities = [ "read" , "list"]
}
path "secret/data/config-server/prod" {
  capabilities = [ "read" , "list"]
}
path "secret/data/config-server" {
  capabilities = [ "read" , "list"]
}
