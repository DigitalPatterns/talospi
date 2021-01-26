# RabbitMQ


#### Step 1 - Steup shared namespace

Create a RabbitMQ namespace and upload the RootCA Bundle as a secret to the namespace

```bash
kubectl create ns rabbitmq
kubectl -n rabbitmq create secret generic ca --from-file='ca.crt=./ca.crt'
```

#### Step 4 - Install RabbitMQ

```bash
kubectl krew install rabbitmq
kubectl rabbitmq install-cluster-operator
kubectl -n rabbitmq create -f cluster/rabbitmq/cert.yaml
kubectl -n rabbitmq create -f cluster/rabbitmq/rabbitmq.yaml
```


### Accessing the RabbitMQ UI

To access the RabbitMQ API you need the following port-forward command:

`kubectl -n rabbitmq port-forward svc/rabbitmq 15671:15671`

Then visit the url: [https://localhost:15671](https://localhost:15671)

To get the admin username/password use the following command:

```bash
kubectl -n rabbitmq get secrets rabbitmq-default-user -o jsonpath='{.data.username}' | base64 -d
kubectl -n rabbitmq get secrets rabbitmq-default-user -o jsonpath='{.data.password}' | base64 -d
```
