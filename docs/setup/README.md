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
7. [Install Talos Config Service](talos_config.md)
8. [Install Postgresql DB (non HA)](postgresql.md)
9. [Install Mongo DB](mongodb.md)
10. [Install Redis](redis.md)
11. [Install Keycloak](keycloak.md)
12. [Install FormAPI & FormBuilder](form_services.md)
13. [How to seed Refdata and setup the Postgrest API](refdata.md)


### Monitoring

I use lens to monitor my cluster automatically from any machine. Follow the guide at [k8slens](https://k8slens.dev/)
for how to install. They can also automatically install Prometheus for you into a lens-metrics namespace. 
Currently, this has a small bug which requires you to edit the deployment file.
Bug report - [https://github.com/lensapp/lens/issues/391](https://github.com/lensapp/lens/issues/391)


Step to workaround bug:

`kubectl -n lens-metrics edit deployments kube-state-metrics`

Change the following lines to match

```yaml
    spec:
      affinity:
        nodeAffinity:
          requiredDuringSchedulingIgnoredDuringExecution:
            nodeSelectorTerms:
            - matchExpressions:
              - key: kubernetes.io/os
                operator: In
                values:
                - linux
              - key: kubernetes.io/arch
                operator: In
                values:
                - arm64
            - matchExpressions:
              - key: beta.kubernetes.io/os
                operator: In
                values:
                - linux
              - key: beta.kubernetes.io/arch
                operator: In
                values:
                - arm64
      containers:
      - image: k8s.gcr.io/kube-state-metrics/kube-state-metrics:v2.0.0-alpha.3
```

Once saved this will pull the correct image for the arm64 and deploy. After which you will be able to see metrics in Lens.

