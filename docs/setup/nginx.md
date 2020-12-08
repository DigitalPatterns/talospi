# Nginx Ingress & MetalLB



kubectl create ns metallb-system
kubectl apply -f https://raw.githubusercontent.com/metallb/metallb/v0.9.5/manifests/metallb.yaml
kubectl create secret generic -n metallb-system memberlist --from-literal=secretkey="$(openssl rand -base64 128)"

kubectl apply -f cluster/metallb/config.yaml

helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx

helm repo update

kubectl create ns ingress-nginx

helm -n ingress-nginx install nginx ingress-nginx/ingress-nginx

