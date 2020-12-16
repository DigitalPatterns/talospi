path "secret/data/precog-dashboard/dev" {
  capabilities = [ "read" ]
}
path "secret/data/precog-dashboard" {
  capabilities = [ "read" , "list"]
}
path "secret/data/config-server/dev" {
  capabilities = [ "read" , "list"]
}
path "secret/data/config-server" {
  capabilities = [ "read" , "list"]
}
