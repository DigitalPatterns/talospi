# Setup MicroK8s

The kubernetes distribution we are going to use is Microk8s from Ubuntu.
[microk8s.io](https://microk8s.io)


#### Step 1 - Install MicroK8s
Log into each of the pi nodes 1..4 and issue the following commands to install MicroK8s

```bash
snap install microk8s --classic
sudo usermod -a -G microk8s ubuntu
sudo iptables -P FORWARD ACCEPT
sudo ufw allow in on cni0 && sudo ufw allow out on cni0
microk8s.start
```


#### Step 2 - Setup the master node

Run the following command on the master to initialise and setup the services
```microk8s enable dns ingress rbac```


#### Step 3 - Join the nodes to the cluster

On the master node **pi1** issue the following command to make it ready for a node to join:
```microk8s.add-node```
The above command will give you a command to run on the first slave node **pi2** like follows
`microk8s.join <master_ip>:<port>/<token>`

Repeat the commands above for the other two node pi3 & pi4.

Once all the nodes have joined you will be able to see their status with:
`microk8s.kubectl get node`

#### Step 4 - Label the nodes

On nodes pi2-4 issue the following command, this will allow K8s to know which nodes have the USB storage attached:
`kubectl label nodes pi4 disktype=ssd`
