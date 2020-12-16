path "secret/data/talos-ui/dev" {
  capabilities = [ "read" ]
}
path "secret/data/talos-ui" {
  capabilities = [ "read" , "list"]
}
path "secret/data/config-server/dev" {
  capabilities = [ "read" , "list"]
}
path "secret/data/config-server" {
  capabilities = [ "read" , "list"]
}
