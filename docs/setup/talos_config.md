# Talos Config Service

To ensure a consistent and secure approach to configuration for the Talos services we created a config service which 
uses Vault as its backend.

This is released as a private docker container, as such you need a docker registry secret within you namespace.

```bash
kubectl -n vault create secret docker-registry regcred --docker-server=https://index.docker.io/v1/ \
 --docker-username=<your-name> --docker-password=<your-pword> --docker-email=<your-email>
```

Install the config service to the cluster

```bash
helm -n vault install configservice helm/configservice
```


Create a new KV keystore version 2 called *secrets*

![](../images/configservice/keystore1.png)

![](../images/configservice/keystore2.png)


Once the keystore is created; then create a new secret under the *secret* path called *config-service/$ENV* where $ENV 
is 'dev' for Development or 'prod' for Production. The secret should then contain the following sample json.


```json
{
  "auth.realm": "rocks",
  "auth.url": "https://keycloak.pi.talos.rocks",
  "businessKeyUrl": "https://formapi.pi.talos.rocks/form/keys/businessKey",
  "consul.datacenter": "talospi",
  "consul.url": "https://consul-server.consul.svc.cluster.local:8501",
  "database.driver-class-name": "org.postgresql.Driver",
  "document.store.uri": "mongodb://camundaAdmin:TALOS@mongodb-0.mongodb.databases.svc.cluster.local:27017,mongodb-1.mongodb.databases.svc.cluster.local:27017,mongodb-2.mongodb.databases.svc.cluster.local:27017/talos?replicaSet=rs0&authSource=admin&ssl=true&retryWrites=true&w=majority",
  "engine.webhook.url": "https://engine.pi.talos.rocks",
  "fileUploadApi.url": "https://fileuploadservice.pi.talos.rocks",
  "formApi.url": "https://formapi.pi.talos.rocks",
  "hibernate.properties.dialect": "org.hibernate.dialect.PostgreSQL95Dialect",
  "notificationApi.url": "https://notification.default.svc.cluster.local",
  "openapi.docs.enabled": true,
  "realtimeProcessDashboard.url": "https://talosprocessdashboard.pi.talos.rocks",
  "redis.host": "redis.databases.svc.cluster.local",
  "redis.ssl": "false",
  "redis.token": "",
  "refData.url": "https://postgrest.pi.talos.rocks",
  "server-port": "8443",
  "serviceDesk.url": "https://github.com/digitalpatterns",
  "ssl.enabled": "true",
  "swagger.auth.realm": "master",
  "tracing.enabled": false,
  "tracing.zipkin.baseUrl": "http://zipkin.default.svc.cluster.local:9411",
  "workflow.support.url": "https://supporting-services.default.svc.cluster.local",
  "workflowApi.url": "https://engine.pi.talos.rocks"
}
```
