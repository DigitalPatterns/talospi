# RefData

To enable the Ref data service there is two parts. The first is to seed the Postgres database with the DB schema using 
the refdata helm job. The second installs the [Postgrest API](https://postgrest.org)

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
