# Postgres setup

For postgres we create a minimal physical volume using the helm chart and boot a single node instance. Settings in helm
can be overridden using the standard overrides.

Create a kubernetes secret for the user Postgres, then install the helm job.

```bash
kubectl create ns databases
echo $( LC_ALL=C tr -dc 'A-Za-z0-9' </dev/urandom | head -c 25) > db.password
kubectl -n databases create secret generic postgresql --from-file='password=./db.password'
helm -n databases install postgresql helm/postgresql
```
