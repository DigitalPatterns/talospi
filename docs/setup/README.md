# Raspberry PI Cluster - Setup guide

This is a guide to building a kubernetes cluster upon the Raspberry PI.


The following pages describes the [parts used](parts_list.md) to build the K8s cluster.

### Steps

1. [Build the pi cluster](build_the_pi.md)
2. [Setup pi desktop manager](pi_desktop.md) (Including bootstrapping K3s and Longhorn storage)
3. [Bootstrap Consul](consul_bootstrap.md)
4. [Bootstrap Vault](vault_bootstrap.md)
5. [Setup Cert Manager with Internal TLS and switch Vault to use TLS](cert_manager_bootstrap.md)
6. [Upgrade Consul to use TLS](upgrade_consul_to_tls.md)
7. [Install Metallb and NGINX proxy ingress](nginx.md)
8. [Install Postgresql DB (non HA)](postgresql.md)
9. [Install Mongo DB](mongodb.md)
10. [Install Redis](redis.md)
11. [Install RabbitMq](rabbitmq.md)
12. [Install Keycloak](keycloak.md)
13. [Install Prometheus monitoring](prometheous.md)


### Enterprise steps

1. [Install Talos Config Service](talos_config.md)
2. [Install FormAPI & FormBuilder](form_services.md)
3. [How to seed Refdata and setup the Postgrest API](refdata.md)
4. [How to setup the initiator services](initiator_services.md)
5. [How to setup the notification gateway](notification_gateway.md)
6. [How to setup the supporting services](supporting_services.md)
7. [How to setup the Workflow engine](talos_engine.md)
8. [How to setup the Talos Platform UI](talos_ui.md)
9. [How to setup the dashboard]()


### Monitoring

I use lens to monitor my cluster automatically from any machine. Follow the guide at [k8slens](https://k8slens.dev/)
for how to install. Then ensure you go to the settings and select the helm *Prometheus* mode which will allow you to see
embedded metrics within the app.
