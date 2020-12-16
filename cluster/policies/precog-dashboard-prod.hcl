path "secret/data/precog-dashboard/prod" {
  capabilities = [ "read" ]
}
path "secret/data/precog-dashboard" {
  capabilities = [ "read" , "list"]
}
path "secret/data/config-server/prod" {
  capabilities = [ "read" , "list"]
}
path "secret/data/config-server" {
  capabilities = [ "read" , "list"]
}
