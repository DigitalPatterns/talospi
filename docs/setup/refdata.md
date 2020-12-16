# RefData

To enable the Ref data service there is three parts. The first is to seed the Postgres database with the DB schema using 
the refdata helm job. The second installs the [Postgrest API](https://postgrest.org), lastly the third setups the 
reference data service ui.

### RefData Seed

This job uses a [flyway](https://flywaydb.org/) container which includes the schemas for the refdata. These can be found here - [Refdata schema](https://github.com/DigitalPatterns/RefData/tree/master/schemas/reference).

If the schema has been updated; once github has published a new container the job can be rerun to deploy the next version.

```bash
helm -n databases install refdata helm/refdata --set refdata.db.defaultPassword="RootDbPasswrd" --set refdata.db.ownerPassword="refOwnerPWD" --set refdata.db.authenticatorPassword="authPWD"
```


### Postgrest API

Run the following to setup the postgrest API. (This will download and setup the keycloak certificate as a secret and 
also set the authenticator db access password.)

```bash
helm -n databases install postgrest helm/postgrest --set postgrest.db.jwtSecret="$(curl -s https://keycloak.pi.talos.rocks/auth/realms/rocks/protocol/openid-connect/certs | jq -rc '.keys | first | {kid, kty, alg, n, e}' | base64)" --set postgrest.db.uri="postgres://authuser:authPWD@postgresql.databases.svc.cluster.local:5432/reference?ssl=prefer"
```


#### Create Postgrest Keycloak settings

Postgrest protects the database through by checking the token presented to it from Keycloak. These are validated against
the audience and a claim. This then allows postgrest to switch to a readonly or service role matching the token.


##### Readonly scope

To create the readonly scope, first go into *Client Scopes* and add a new scope called *Refdata-readonly*. Once that is 
created you then need to apply two custom mappers to the scope.
Services that need to Readonly access to more sensitive data in the DB should have the *Refdata-readonly* client scope 
added to them.


###### Audience mapper

 * Name: postgrest-aud
 * Mapper Type: Audience
 * Custom Audience: postgrest
 * Add to ID Token: On
 * Add to Access Token: On 
![](../images/postgrest/readonly-mapper1.png)


###### Hardcoded Claim

 * Name: postgrest
 * Mapper Type: Hardcoded claim
 * Token Claim Name: postgrest
 * Claim value: readonlyuser
 * Clain JSON Type: String
 * Add to ID Token: On
 * Add to Access Token: On
 * Add to userinfo
![](../images/postgrest/readonly-mapper2.png)


![](../images/postgrest/readonly-mappers.png)


##### Service User scope

To create the service user scope, first go into *Client Scopes* and add a new scope called *Refdata-serviceuser*. 
Once that is created you then need to apply two custom mappers to the scope. 
Services that need to Select, Update or Insert rows into the DB should have the *Refdata-serviceuser* client scope 
added to them.

![](../images/postgrest/service-user-scope.png)

###### Audience mapper 

 * Name: postgrest-aud
 * Mapper Type: Audience
 * Custom Audience: postgrest
 * Add to ID Token: On
 * Add to Access Token: On 
![](../images/postgrest/service-user-scope-mapper1.png)


###### Hardcoded Claim

 * Name: postgrest
 * Mapper Type: Hardcoded claim
 * Token Claim Name: postgrest
 * Claim value: serviceuser
 * Clain JSON Type: String
 * Add to ID Token: On
 * Add to Access Token: On
 * Add to userinfo
![](../images/postgrest/service-user-scope-mapper2.png)


#### OpenAPI

An OpenAPI (swagger) schema will now be avaliable at the route of the postgrest domain 
[https://postgrest.pi.talos.rocks/](https://postgrest.pi.talos.rocks/). This is best viewed when loaded into a swagger UI.


### Reference Data Service UI

The enterprise Talos version of the reference data service uses the Talos config service for its secrets; The opensource
version uses AWS Secrets manager. To use the open source version replace the Vault steps below with the appropriate
setup steps for secrets manager, ensuring there is a set of AWS access credentials that has access to the required 
secret.

For the reference service ui to be fully functional, it requires the complete Talos Stack. To enable New dataset 
requests, updates and deletes this needs the workflow engine backend, the formAPI service and the workflow portal 
frontend. This is because before changes to data are allowed they need to be approved. Approvals are controlled through 
the use of BPMN's.


#### Vault setup

Create a policy in Vault for the referencedataservice and apply the token given as a kubernetes secret. 
Replace *<VAULT_TOKEN>* with the root vault token. `export ENV=dev` Where the environment is 'Development (dev)' or 
'Production (prod)'. For other environments you will need to update the policy hcl file to match.

```bash
kubectl -n vault port-forward service/vault 8200:8200 &
export VAULT_ADDR="https://127.0.0.1:8200"
export VAULT_TOKEN="<VAULT_TOKEN>"
vault policy write -tls-skip-verify reference-data-service cluster/policies/reference-data-service-${ENV}.hcl
vault token create -tls-skip-verify -period=8760h -policy=reference-data-service -explicit-max-ttl=8760h
kubectl create secret generic referencedataservice --from-literal=token=$TOKEN
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
*reference-data-service/$ENV* 

[https://localhost:8200/ui/vault/secrets/secret/list](https://localhost:8200/ui/vault/secrets/secret/list)

```json
{
  "addDataRowProcess": "addDataRowProcess",
  "auth.clientId": "referencedataservice",
  "deleteDataRowProcess": "deleteDataRowProcess",
  "deleteDataSetProcess": "deleteDataSetProcess",
  "editDataRowProcess": "editDataRowProcess",
  "newDataSetForm": "newDataSetRequest",
  "newDataSetProcess": "newDataSetRequest",
  "editDataRowForm":  "editDataRowForm",
  "deleteDataRowForm": "deleteDataRowForm",
  "uiEnvironment": "dev",
  "uiVersion": "alpha"
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
  "auth.clientId": "referencedataservice",
  "uiEnvironment": "dev",
  "uiVersion": "alpha",
  "tracing.enabled": true,
  "newDataSetForm": "newDataSetRequest",
  "newDataSetProcess": "newDataSetRequest",
  "deleteDataSetProcess": "deleteDataSetProcess",
  "addDataRowProcess": "addDataRowProcess",
  "editDataRowProcess": "editDataRowProcess",
  "deleteDataRowProcess": "deleteDataRowProcess",
  "editDataRowForm":  "editDataRowForm",
  "deleteDataRowForm": "deleteDataRowForm"
}
```


Install the Reference data service UI to the cluster

##### Enterprise version

```bash
helm install referencedataservice helm/referencedataservice
```

##### Opensource version

Create the *referencedataservice* secret with the AWS credentials that enable the service to talk to the AWS secrets 
manager.

```bash
kubectl create secret generic referencedataservice --from-literal=awsAccessKey=$AWS_ACCESS_KEY \
  --from-literal=awsSecretKey=$AWS_SECRET_KEY
helm install referencedataservice helm/referencedataservice \
  --set referencedataservice.secretsManagerEnabled=true \
  --set referencedataservice.image.repository: digitalpatterns/reference-data-service \
  --set referencedataservice.image.tag: latest
```


