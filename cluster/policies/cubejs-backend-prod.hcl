path "secret/data/talos-cubejs-backend/prod" {
  capabilities = [ "read" ]
}
path "secret/data/talos-cubejs-backend" {
  capabilities = [ "read" , "list"]
}
path "secret/data/config-server/prod" {
  capabilities = [ "read" , "list"]
}
path "secret/data/config-server" {
  capabilities = [ "read" , "list"]
}
