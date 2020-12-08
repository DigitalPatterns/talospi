# PI Desktop Management node


We will use the Pi400 as a simple desktop management node. This node will not run K8s but will be able to run kubectl 
commands and bootstrap the cluster.


#### Step 1 - update the OS

```bash
sudo apt update && apt upgrade -y
```

#### Step 2 - install missing packages

```bash
apt install curl
```


#### Step 3 - Update the hosts table
update /etc/hosts adding in the pi names, this will allow all the cluster nodes to address each other correctly.

`vim /etc/hosts`

```bash
127.0.0.1 localhost
192.168.99.2 ubuntu-desktop
192.168.99.101 pi1
192.168.99.102 pi2
192.168.99.103 pi3
192.168.99.104 pi4
```


#### Step 4 - K3sup

We will be using the Kubernetes distribution k3s from Rancher.io. To make this easier to install we use a tool called
k3sup.

```bash
curl -sLS https://get.k3sup.dev | sh
sudo install k3sup /usr/local/bin/
```

k3sup uses SSH to connect to each node and perform its installation, in order for this to work well you need an SSH key
with the public part distributed to each node.

Create and ssh key with the following command: `ssh-keygen`

Then repeat the following command for every node:  `ssh-copy-id ubuntu@pi1` (replace *pi1* with the correct node names)


#### Step 5 - Bootstrap k3s

##### Master node 1

On the pi management desktop export the following IP, (which points to the first master node)

`export SERVER_IP=192.168.99.101`

The next command bootstraps the master node setting up k3s by downloading the required files.

```bash
k3sup install \
  --ip $SERVER_IP \
  --user ubuntu \
  --cluster
```


##### Master nodes 2 / 3

In order to enable a HA setup, kubernetes requires 3 master nodes. To enable HA mode run the next command twice changing 
the *NEXT_SERVER_IP* each time to point to the next master in the set.

```bash
export NEXT_SERVER_IP=192.168.0.102
k3sup join \
  --ip $NEXT_SERVER_IP \
  --user ubuntu \
  --server-user ubuntu \
  --server-ip $SERVER_IP \
  --server 
```


##### Agent nodes
 
Now you have a HA Kubernetes cluster, any additional nodes you have will become agents. You can join these to the cluster
with the following command:

```bash
export NEXT_AGENT_IP=192.168.99.104
k3sup join \
  --ip $NEXT_AGENT_IP \
  --user ubuntu \
  --server-ip $SERVER_IP \
```

(again dont forget to change the *NEXT_AGENT_IP* each time)


#### Step 5 - Storage space

To enable storage for kubernetes clusters we will use Longhorn (also from Rancher.io). Install with the following 
commands:

```bash
kubectl create namespace longhorn-system
helm install -n longhorn-system  longhorn helm/longhorn 
```

Once all the packages have deployed you can connect to the Longhorn UI to see their status. This is only available on 
the cluster as there is no ingress. To see it run the following portforward command:
`kubectl -n longhorn-system port-forward service/longhorn-frontend 8082:80` After which you can connect via a browser to
[http://localhost:8082](http://localhost:8082)


