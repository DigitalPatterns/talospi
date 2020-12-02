# Postgres setup

For postgres we create a minimal physical volume using the helm chart and boot a single node instance. Settings in helm
can be overridden using the standard overrides.

Create a kubernetes secret for the user Postgres (replacing PASSWORD_HERE with your real password), then install the 
helm job.__

```bash
kubectl -n databases create secret generic postgresql --from-literal=password=PASSWORD_HERE
helm -n databases install postgresql helm/postgresql
```
