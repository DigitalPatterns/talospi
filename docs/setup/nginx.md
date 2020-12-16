# Nginx Ingress & MetalLB

#### Metallb

Metallb is an optional HA load balancer designed to make the Nginx proxy available as a HA proxy ingress for your cluster.

```bash
kubectl create ns metallb-system
kubectl apply -f https://raw.githubusercontent.com/metallb/metallb/v0.9.5/manifests/metallb.yaml
kubectl create secret generic -n metallb-system memberlist --from-literal=secretkey="$(openssl rand -base64 128)"
kubectl apply -f cluster/metallb/config.yaml
```


#### Nginx deployment

The following deployment steps will deploy an Nginx ingress to you cluster (removing the default k3s old version of traefik)

```bash
helm -n kube-system delete traefik
kubectl create ns nginx
helm -n nginx repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm -n nginx install nginx ingress-nginx/ingress-nginx
```
