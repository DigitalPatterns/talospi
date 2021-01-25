# Keycloak setup


#### - Step 1 Create a database

Enter the postgres pod using the command below then enter the SQL commands to create the database, user and grant the 
user permissions.

`kubectl -n databases exec -it postgresql-0 -- psql`

Then execute the following SQL commands:

```sql
CREATE DATABASE keycloak;
create user keycloak with encrypted password 'CHANGE_ME';
grant all privileges on database keycloak to keycloak;
```

store a copy of the password to a file called `keycloakDbPassword` for use later


#### Step 2 - Create namespace and add secret

Create a kubernetes secret for Keycloak with the settings

```bash
kubectl create ns keycloak
kubectl -n keycloak create secret generic keycloak --from-file=DB_PASSWORD=./keycloakDbPassword --from-literal=DB_USER=keycloak
```

As this namespace does not yet have the RootCA in you should add it now:

`kubectl -n keycloak create secret generic ca --from-file='ca.crt=./ca.crt'`


#### Step 3 - Deploy Keycloak

```bash
helm -n keycloak install keycloak helm/keycloak
```


#### Step 4 - Setup Admin user

In order to setup the admin user, the first time you connect to Keycloak you must port forward to port 8080.

`kubectl -n keycloak port-forward keycloak-0 8080:8080`

Then connect on a browser via [http://localhost:8080](http://localhost:8080) and follow the on screen prompts.


#### Step 5 - Import rocks realm

To speed up deployment you can import the sample realm from 
[https://raw.githubusercontent.com/DigitalPatterns/talospi/main/cluster/keycloak/realm-export.json](https://raw.githubusercontent.com/DigitalPatterns/talospi/main/cluster/keycloak/realm-export.json)


