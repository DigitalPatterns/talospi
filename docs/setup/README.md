# Raspberry PI Cluster - Setup guide

This is a guide to building a kubernetes cluster upon the Raspberry PI.


The following pages describes the [parts used](parts_list.md) to build the K8s cluster.

### Steps

1. [Build the pi cluster](build_the_pi.md)
2. [Setup MicroK8s](microk8s.md)
3. [Setup Ceph storage](ceph.md)
4. [Bootstrap Consul](consul_bootstrap.md)
5. [Bootstrap Vault](vault_bootstrap.md)
6. [Setup Cert Manager with Internal TLS and switch Vault to use TLS](cert_manager_bootstrap.md)
7. [Upgrade Consul to use TLS](upgrade_consul_to_tls.md)
8. [Install Talos Config Service](talos-config.md)
9. [Install Postgresql DB (non HA)](postgresql.md)
10. [Install Mongo DB](mongodb.md)
