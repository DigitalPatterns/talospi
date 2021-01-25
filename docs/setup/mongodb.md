# MongoDB

We use a clustered secure instance of MongoDB to store most of our data, to enable this we can install MongoDB as follows:


#### Step 1 - Password

Create an admin user password and load this as a k8s secret
```bash
echo -n $( LC_ALL=C tr -dc 'A-Za-z0-9' </dev/urandom | head -c 25) > tmp/mongo.password
kubectl -n databases create secret generic mongodb --from-file=password=./tmp/mongo.password
```


#### Step 2 - Replication Security

To enable each of the nodes to securely talk to each other we need to give them a shared key, This can be done using 
the following commands. The first creates a secure key, the second uploads this as a k8s secret.

```bash
echo -n "- $(openssl rand -base64 756 | tr -d '\n')" > tmp/mongo.key
kubectl -n databases create secret generic mongo-keyfile --from-file=mongo.key=./tmp/mongo.key
```


#### Step 3 - Deploy MongoDB

We will deploy MongoDB using our Helm chart as follows:

```bash
helm -n databases install mongodb helm/mongodb
```


#### Step 4 - Activate replication

Before MongoDB will come online you need to connect to a node and activate replication, this allows the master to know
where to find the other nodes and sets up communication / replication between them.

Connect to the first MongoDB pod once it is running:
 
`kubectl -n databases exec -it mongodb-0 -- sh`

Once inside the pod connect to the local MongoDB instance.
`mongo  --tlsAllowInvalidCertificates  --tls --tlsCertificateKeyFile=/certificates/mongo.pem mongodb://admin:MONGO@mongodb-0.mongodb.databases.svc.cluster.local:27017/`

Now you are connected to the MongoDB shell you issue the following command to setup replication:

```bash
rs.initiate( {
   _id : "rs0",
   members: [
      { _id: 0, host: "mongodb-0.mongodb.databases.svc.cluster.local:27017" },
      { _id: 1, host: "mongodb-1.mongodb.databases.svc.cluster.local:27017" },
      { _id: 2, host: "mongodb-2.mongodb.databases.svc.cluster.local:27017" }
   ]
})
```

To exit the MongoDB shell & the pod do `Ctrl + d` twice
