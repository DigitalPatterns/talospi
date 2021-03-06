### Workflow Initiator Services

Workflow initiator services is an enterprise feature of the Talos platform.

It requires the following services:
* Consul
* Postgres
* Talos Engine
* MongoDB


##### Keycloak Setup

Within keycloak you need a ClientID/Secret. Below are the settings required:

###### ClientID

You need to create a *initiator* confidential client
![](../images/initiatorservices/keycloak_client1.png)

Ensure the camunda-rest-api mapper is assigned as a scope.

![](../images/initiatorservices/keycloak_client2.png)

You also need to grab the Client Secret from the second tab.


###### Group

You need to create a group called *initiators*
![](../images/initiatorservices/keycloak_group.png)

###### User

You need to create a user for the supporting services, this should be as follows:
![](../images/initiatorservices/keycloak_user1.png)

Ensure the user is part of the *initiators* group
![](../images/initiatorservices/keycloak_user2.png)
 

#### Consul setup

Access the consul ui by port-forwarding with the following command:

`kubectl -n consul port-forward svc/consul-ui 8443:443`

Get the access token for the UI with the following command:

`kubectl -n consul get secrets consul-bootstrap-acl-token -o jsonpath='{.data.token}' | base64 -d`

Go to the following web link: [https://localhost:8443/ui/talospi/acls/tokens](https://localhost:8443/ui/talospi/acls/tokens)

Under policies create the following Consul Policy called *initiatorservices*
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

Create a token for the initiator services

![](../images/initiatorservices/consul.png)

Grab the token as this will be needed in the later steps to be added into Vault.


#### Postgres DB setup

Initiator services requires a postgres database. This can be added to postgres using the following:

` kubectl -n databases exec -it postgresql-0 -- psql`

Once in the postgres shell then run the following sql:

```sql
create database initiatorservices;
create user initiator_services_admin with encrypted password 'CHANGE_ME';
grant all privileges on database initiatorservices to initiator_services_admin;
```


#### Vault setup

Create a policy in Vault for the initiatorservices and apply the token given as a kubernetes secret. 
Replace *<VAULT_TOKEN>* with the root vault token. `export ENV=dev` Where the environment is 'Development (dev)' or 
'Production (prod)'. For other environments you will need to update the policy hcl file to match.

```bash
kubectl -n vault port-forward service/vault 8200:8200
export VAULT_ADDR="https://127.0.0.1:8200"
export VAULT_TOKEN="<VAULT_TOKEN>"
vault policy write -tls-skip-verify initiator-services cluster/policies/initiator-services-${ENV}.hcl
vault token create -tls-skip-verify -period=8760h -policy=initiator-services -explicit-max-ttl=8760h
kubectl create secret generic initiatorservices --from-literal=token=$TOKEN
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
*talos-initiators/$ENV* 

[https://localhost:8200/ui/vault/secrets/secret/list](https://localhost:8200/ui/vault/secrets/secret/list)

```json
{
  "api.allowedAudiences": "support-services",
  "auth.clientId": "initiator",
  "auth.clientSecret": "<CHANGEME>",
  "auth.password": "<CHANGEME>",
  "auth.username": "initiatoruser",
  "consul.acl-token": "<CHANGEME>",
  "db.alert.businessKeyField": "beaconnum",
  "db.alert.dbOnProcess": "update alertlog set is_processed=true,processed_utcdatetime=current_timestamp where alertid=:#alertid",
  "db.alert.dbSelect": "select * from alertlog where is_processed = false order by alertutcdatetime limit 5",
  "db.alert.driverClassName": "org.postgresql.Driver",
  "db.alert.password": "<CHANGEME>",
  "db.alert.pollingPeriod": "10s",
  "db.alert.primaryKeyField": "alertid",
  "db.alert.processKey": "alert",
  "db.alert.url": "jdbc:postgresql://postgresql.databases.svc.cluster.local:5432/initiatorservices?sslmode=prefer&currentSchema=public",
  "db.alert.username": "initiator_services_admin",
  "db.alert.variableName": "alert",
  "mail.trackisafe.host": "imap.<CHANGEME>.com",
  "mail.trackisafe.password": "<CHANGEME>",
  "mail.trackisafe.processKey": "trackisafe",
  "mail.trackisafe.username": "<CHANGEME>",
  "talos.initiators.db.polling.key": "",
  "talos.initiators.mail.polling.key": ""
}
```


##### Deploy

Deploy Initiator services to the cluster

```bash
helm install initiatorservices helm/initiatorservices
```
