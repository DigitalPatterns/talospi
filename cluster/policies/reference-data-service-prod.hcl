path "secret/data/reference-data-service/prod" {
  capabilities = [ "read" ]
}
path "secret/data/reference-data-service" {
  capabilities = [ "read" , "list"]
}
path "secret/data/config-server/prod" {
  capabilities = [ "read" , "list"]
}
path "secret/data/config-server" {
  capabilities = [ "read" , "list"]
}
