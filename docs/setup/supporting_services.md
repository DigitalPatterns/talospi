### Workflow Supporting Services

Workflow supporting services is an enterprise feature of the Talos platform.

It requires the following services:
* Consul
* Postgres
* Talos Engine
* MongoDB


##### Keycloak Setup

Within keycloak you need a ClientID/Secret. Below are the settings required:

###### ClientID

You need to create a *supportingservices* confidential client
![](../images/supportingservices/keycloak_client1.png)

Ensure the camunda-rest-api mapper is assigned as a scope.

![](../images/supportingservices/keycloak_client2.png)

You also need to grab the Client Secret from the second tab.


###### User

You need to create a user for the supporting services, this should be as follows:
![](../images/supportingservices/keycloak_user1.png)

Ensure the user is part of the *camunda-admins* group
![](../images/supportingservices/keycloak_user2.png)

 
#### Consul setup

Access the consul ui by port-forwarding with the following command:

`kubectl -n consul port-forward svc/consul-ui 8443:443`

Get the access token for the UI with the following command:

`kubectl -n consul get secrets consul-bootstrap-acl-token -o jsonpath='{.data.token}' | base64 -d`

Go to the following web link: [https://localhost:8443/ui/talospi/acls/tokens](https://localhost:8443/ui/talospi/acls/tokens)

Under policies create the following Consul Policy called *supportingservices*
```hcl
node_prefix "" {
  policy = "write"
}
service_prefix "" {
  policy = "read"
}
key_prefix "camel" {
  policy = "write"
}
agent_prefix "" {
  policy = "read"
}
session_prefix "" {
  policy = "write"
}
```

Create a token for the supporting services
![](../images/supportingservices/consul.png)

Grab the token as this will be needed in the later steps to be added into Vault.

#### Postgres DB setup

Supporting services requires a postgres database. This can be added to postgres using the following:

` kubectl -n databases exec -it postgresql-0 psql`

Once in the postgres shell then run the following sql:

```sql
create database supportingservices;
create user supporting_services_admin with encrypted password 'CHANGE_ME';
grant all privileges on database supportingservices to supporting_services_admin;
```


#### Vault setup

Create a policy in Vault for the supportingservices and apply the token given as a kubernetes secret. 
Replace *<VAULT_TOKEN>* with the root vault token. `export ENV=dev` Where the environment is 'Development (dev)' or 
'Production (prod)'. For other environments you will need to update the policy hcl file to match.

```bash
kubectl -n vault port-forward service/vault 8200:8200
export VAULT_ADDR="https://127.0.0.1:8200"
export VAULT_TOKEN="<VAULT_TOKEN>"
vault policy write -tls-skip-verify supporting-services cluster/policies/supporting-services-${ENV}.hcl
vault token create -tls-skip-verify -period=8760h -policy=supporting-services -explicit-max-ttl=8760h
kubectl create secret generic supportingservices --from-literal=token=$TOKEN
```


You need to ensure you have registry credential setup in the environment that allow access to docker hub. 
This can be done with the following command:

```bash
kubectl create secret docker-registry regcred --docker-server=https://index.docker.io/v1/ \
 --docker-username=<your-name> --docker-password=<your-pword> --docker-email=<your-email>
```

##### Vault Secret setup

In Vault two sets of secrets are required. The application will read most of the settings from the shared config secret.
[talos_config](talos_config.md)

In addition, you need to create a new secret in the secrets key value store under the path
*talos-support/$ENV* 

[https://localhost:8200/ui/vault/secrets/secret/list](https://localhost:8200/ui/vault/secrets/secret/list)

```json
{
  "api.allowedAudiences": "support-services",
  "auth.clientId": "supportservices",
  "auth.clientSecret": "<CHANGEME>",
  "auth.password": "<CHANGEME>",
  "auth.username": "supportservices@pi.talos.rocks",
  "consul.acl-token": "<CHANGEME>",
  "daily.task.open.reminder.cron.expression": "0 0 10 * * ?",
  "daily.task.open.reminder.timezone": "Europe/London",
  "database.password": "<CHANGEME>",
  "database.url": "jdbc:postgresql://postgresql.databases.svc.cluster.local:5432/supportingservices?sslmode=prefer&currentSchema=public",
  "database.username": "supporting_services_admin"
}
```


##### Install supporting services

Install the Supporting service to the cluster

```bash
helm install supportingservices helm/supportingservices
```
