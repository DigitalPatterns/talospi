### Workflow Initiator Services

Workflow initiator services is an enterprise feature of the Talos platform.

It requires the following services:
* Consul
* Postgres
* Talos Engine
* MongoDB


Keycloak - Client Scope:
* supporting-services
    -> audience mapper: supporting-services
 

Consul Policy - initiatorservices
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

#### Postgres DB setup

Initiator services requires a postgres database. This can be added to postgres using the following:

` kubectl -n databases exec -it postgresql-0 psql`

Once in the postgres shell then run the following sql:

```sql
create database initiatorservices;
create user supporting_services_admin with encrypted password 'CHANGE_ME';
grant all privileges on database initiatorservices to supporting_services_admin;
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
*talos-engine/$ENV* 

[https://localhost:8200/ui/vault/secrets/secret/list](https://localhost:8200/ui/vault/secrets/secret/list)

```json
{
  "api.allowedAudiences": "support-services",
  "auth.clientId": "initiator",
  "auth.clientSecret": "<CHANGEME>",
  "auth.password": "<CHANGEME>",
  "auth.username": "initiatoruser@pi.talos.rocks",
  "consul.acl-token": "<CHANGEME>",
  "db.alert.businessKeyField": "beaconnum",
  "db.alert.dbOnProcess": "update alertlog set is_processed=true,processed_utcdatetime=current_timestamp where alertid=:#alertid",
  "db.alert.dbSelect": "select * from alertlog where is_processed = false order by alertutcdatetime limit 5",
  "db.alert.driverClassName": "org.postgresql.Driver",
  "db.alert.password": "<CHANGEME>",
  "db.alert.pollingPeriod": "10s",
  "db.alert.primaryKeyField": "alertid",
  "db.alert.processKey": "alert",
  "db.alert.url": "jdbc:postgresql://postgresql.databases.svc.cluster.local:5432/alerts?sslmode=prefer&currentSchema=public",
  "db.alert.username": "<CHANGEME>",
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
