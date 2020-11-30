# Setup Rook Ceph Storage


To enable storage we are going to use Ceph managed with Rook from [rook.io](rook.io). 
This will allow for highly available 3 replicas of storage, which be used as a storageClass
inside our K8s cluster.



#### Step 1 - Install the rook operator

```bash
helm repo add rook-release https://charts.rook.io/release
kubectl create namespace rook-ceph
helm install --namespace rook-ceph rook-ceph rook-release/rook-ceph --set csi.kubeletDirPath=/var/snap/microk8s/common/var/lib/kubelet
```


#### Step 2 - Install the Ceph cluster

Once the pod is happy running which you can check with the following command `kubectl -n rook-ceph get pods` then we 
can deploy the storage cluster.

```kubectl -n rook-ceph create -f cluster/rook/cluster.yaml```

use the following command to monitor the status of the role out:

```kubectl -n rook-ceph get pods -w -o wide```


#### Step 3 - Setup the Storage class

Once all the pods are online running the following step to create the storageClass
```kubectl -n rook-ceph create -f cluster/rook/storageclass.yaml```


##### Note

If you want to check Cephs status you can deploy the ceph toolbox container to the cluster with the following command:
`kubectl -n rook-ceph create -f cluster/rook/toolbox`

To get into the container do:

```bash
kubectl -n rook-ceph exec -it deploy/rook-ceph-tools -- bash
```
