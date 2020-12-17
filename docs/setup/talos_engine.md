### Workflow Engine

The enterprise Talos version of the Workflow engine uses the Talos config service for its secrets; The opensource
version uses AWS Secrets manager. To use the open source version replace the Vault steps below with the appropriate
setup steps for secrets manager, ensuring there is a set of AWS access credentials that has access to the required 
secret.


#### Postgres DB setup

Initiator services requires a postgres database. This can be added to postgres using the following:

` kubectl -n databases exec -it postgresql-0 psql`

Once in the postgres shell then run the following sql:

```sql
create database talos_engine;
create user talos_engine_admin with encrypted password 'CHANGE_ME';
grant all privileges on database talos_engine to talos_engine_admin;
```

#### Mongo DB setup

Initiator services requires a postgres database. This can be added to postgres using the following:

`kubectl -n databases exec -it mongodb-0 mongo`

Once in the mongo shell then run the following mongo commands:

```mongojs
use admin
db.createUser(
    {
      user: "camundaAdmin",
      pwd: passwordPrompt(),
      roles: [
        { role: "readWrite", db: "talos" }]
    }
)
use talos
`CTRL-D`
```


#### Keycloak setup

The Reference data UI requires a confidential Keycloak client to be created called *talosengine*
![](../images/talosui/keycloak_client1.png)

Ensure the both the *refdata-serviceuser*, *camunda-rest-api* client scopes are added to the client.
![](../images/talosui/keycloak_client2.png)

Under service account roles -> Realm management ensure the *view-users* role is assigned.
![](../images/talosui/keycloak_client3.png)


#### Vault setup

Create a policy in Vault for the talosengine and apply the token given as a kubernetes secret. 
Replace *<VAULT_TOKEN>* with the root vault token. `export ENV=dev` Where the environment is 'Development (dev)' or 
'Production (prod)'. For other environments you will need to update the policy hcl file to match.

```bash
kubectl -n vault port-forward service/vault 8200:8200 &
export VAULT_ADDR="https://127.0.0.1:8200"
export VAULT_TOKEN="<VAULT_TOKEN>"
vault policy write -tls-skip-verify talos-engine cluster/policies/talos-engine-${ENV}.hcl
vault token create -tls-skip-verify -period=8760h -policy=talos-engine -explicit-max-ttl=8760h
kubectl create secret generic talosengine --from-literal=token=$TOKEN
```


If you are using the enterprise version you need to ensure you have registry credential setup in the environment that
allow access to docker hub. This can be done with the following command:

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
  "auth.clientId": "talosengine",
  "auth.clientSecret": "",
  "aws.access.key": "",
  "aws.s3.formData": "formdata",
  "aws.s3.pdfs": "pdfs",
  "aws.secret.key": "",
  "camunda.admin.group": "camunda-admin",
  "database.driver-class-name": "org.postgresql.Driver",
  "database.password": "<CHANGE_ME>",
  "database.url": "jdbc:postgresql://postgresql.databases.svc.cluster.local:5432/talos_engine?sslmode=prefer&currentSchema=public",
  "database.username": "talos_engine_admin",
  "document.store.uri": "mongodb+srv://camundaAdmin:CHANGE_ME@mongo.databases.svc.cluster.local/talos?retryWrites=true&w=majority",
  "engine.webhook.url": "https://talosengine.pi.talos.rocks",
  "redis.host": "redis.databases.svc.cluster.local",
  "redis.ssl": "false",
  "redis.token": ""
}
```


![](../images/refdataui/reference-secret.png)


##### AWS Secrets Setup

If using secrets manager then the following is an example of the secrets that should be added to a secret named
*/secret/reference-data-service_$ENV*

```json
{

}
```


Install the Reference data service UI to the cluster

##### Enterprise version

```bash
helm install talosengine helm/talosengine
```

##### Opensource version

Create the *talosengine* secret with the AWS credentials that enable the service to talk to the AWS secrets 
manager.

```bash
kubectl create secret generic talosengine --from-literal=awsAccessKey=$AWS_ACCESS_KEY \
  --from-literal=awsSecretKey=$AWS_SECRET_KEY
helm install talosengine helm/talosengine \
  --set talosengine.secretsManagerEnabled=true \
  --set talosengine.image.repository: digitalpatterns/reference-data-service \
  --set talosengine.image.tag: latest
```



