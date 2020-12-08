# RabbitMQ


#### Step 1 - Steup shared namespace

Create a RabbitMQ namespace and upload the RootCA Bundle as a secret to the namespace

```bash
kubectl create ns rabbitmq
kubectl -n rabbitmq create secret generic ca --from-file='ca-bundle.pem=./ca.crt'
```


#### Step 2 - Create shared cluster secret

RabbitMQ nodes and CLI tools use a shared secret known as the Erlang Cookie, to authenticate to each other. 
The cookie value is a string of alphanumeric characters up to 255 characters in size. The value must be generated before 
creating a RabbitMQ cluster since it is needed by the nodes to form a cluster.

With the community Docker image, RabbitMQ nodes will expect the cookie to be at /var/lib/rabbitmq/.erlang.cookie. 
We recommend creating a Secret and mounting it as a Volume on the Pods at this path.

```bash
echo $( LC_ALL=C tr -dc 'A-Za-z0-9' </dev/urandom | head -c 255) > cookie
kubectl -n rabbitmq create secret generic erlang-cookie --from-file=./cookie
```

#### Step 3 - Create admin user credentials

Run the following to seed admin user credentials into a k8s secret.

```bash
echo $( LC_ALL=C tr -dc 'A-Za-z0-9' </dev/urandom | head -c 25) > pass
kubectl -n rabbitmq create secret generic rabbitmq-admin --from-literal=user=admin --from-file=./pass
```

#### Step 4 - Install RabbitMQ

`helm -n rabbitmq install rabbitmq helm/rabbitmq`
