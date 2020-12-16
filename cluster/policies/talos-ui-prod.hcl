path "secret/data/talos-ui/prod" {
  capabilities = [ "read" ]
}
path "secret/data/talos-ui" {
  capabilities = [ "read" , "list"]
}
path "secret/data/config-server/prod" {
  capabilities = [ "read" , "list"]
}
path "secret/data/config-server" {
  capabilities = [ "read" , "list"]
}
