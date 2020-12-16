### Workflow Engine

The enterprise Talos version of the Workflow engine uses the Talos config service for its secrets; The opensource
version uses AWS Secrets manager. To use the open source version replace the Vault steps below with the appropriate
setup steps for secrets manager, ensuring there is a set of AWS access credentials that has access to the required 
secret.


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
  "auth.clientSecret": "2e36dbb7-1c57-42dc-802b-cf30a99a5ede",
  "aws.access.key": "AKIA6D4YQOFARGHPCP56",
  "aws.s3.formData": "dp-dev-form-data",
  "aws.s3.pdfs": "dp-dev-pdfs",
  "aws.secret.key": "o70qM7x2vVCPnxHlDC7BsN2rXqjLsy9bZQMyTYVk",
  "camunda.admin.group": "camunda-admin",
  "database.driver-class-name": "org.postgresql.Driver",
  "database.password": "8UbrzaRy92dtRFzEJX69hwtX",
  "database.url": "jdbc:postgresql://dpservice.cj9hz12nl43u.eu-west-2.rds.amazonaws.com:5432/talos_engine?sslmode=require&currentSchema=public",
  "database.username": "talos_engine_admin",
  "document.store.uri": "mongodb+srv://camundaAdmin:FSPaFZ47HtXAyYZQmbtK3m2fnrndh7PU@dev.he4yv.mongodb.net/talos?retryWrites=true&w=majority",
  "engine.webhook.url": "https://talosengine.dev.digitalpatterns.io",
  "notificationApi.url": "https://notification.default.svc.cluster.local",
  "redis.host": "master.dpcache.lb3uz4.euw2.cache.amazonaws.com",
  "redis.ssl": "true",
  "redis.token": "cmUHGfa4pH3o0fuxMSE3WrncIb77n0Nz"
}
```



*talos-ui/dev*
```json
{
  "admin.role": "process_admin",
  "auth.clientId": "talosui",
  "refData.url": "http://refdataapi.default.svc.cluster.local",
  "reports.precog.name": "Precog Command Center",
  "reports.precog.roles": "precog-dashboard",
  "reports.precog.url": "https://precogdashboard.dev.digitalpatterns.io",
  "serviceDesk.url": "https://github.com/digitalpatterns",
  "tracing.zipkin.ui.url": "https://zipkin.dev.digitalpatterns.io",
  "uiEnvironment": "dev",
  "uiVersion": "ALPHA",
  "workflow.support.url": "https://workflow-support-services.default.svc.cluster.local"
}
```

![](../images/refdataui/reference-secret.png)


##### AWS Secrets Setup

If using secrets manager then the following is an example of the secrets that should be added to a secret named
*/secret/reference-data-service_$ENV*

```json
{
  "server-port": "8443",
  "ssl.enabled": true,
  "auth.url": "https://keycloak.pi.talos.rocks",
  "fileUploadApi.url": "https://fileuploadservice.pi.talos.rocks",
  "refData.url": "https://postgrest.pi.talos.rocks",
  "formApi.url": "https://formapi.pi.talos.rocks",
  "workflowApi.url": "https://engine.pi.talos.rocks",
  "auth.realm": "rocks",
  "auth.clientId": "talosengine",
  "uiEnvironment": "dev",
  "uiVersion": "alpha",
  "tracing.enabled": true,
  "newDataSetForm": "newDataSetRequest",
  "newDataSetProcess": "newDataSetRequest",
  "deleteDataSetProcess": "deleteDataSetProcess",
  "addDataRowProcess": "addDataRowProcess",
  "editDataRowProcess": "editDataRowProcess",
  "deleteDataRowProcess": "deleteDataRowProcess"
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

