path "secret/data/talos-notification-gateway/dev" {
  capabilities = [ "read" ]
}
path "secret/data/talos-notification-gateway" {
  capabilities = [ "read" , "list"]
}
path "secret/data/config-server/dev" {
  capabilities = [ "read" , "list"]
}
path "secret/data/config-server" {
  capabilities = [ "read" , "list"]
}

