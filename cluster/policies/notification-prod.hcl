path "secret/data/talos-notification-gateway/prod" {
  capabilities = [ "read" ]
}
path "secret/data/talos-notification-gateway" {
  capabilities = [ "read" , "list"]
}
path "secret/data/config-server/prod" {
  capabilities = [ "read" , "list"]
}
path "secret/data/config-server" {
  capabilities = [ "read" , "list"]
}

