# Building and Setting up the Pi


## Stage 1 - Building the Pi nodes
Follow the guide here on how to install Ubuntu onto your SSD card, using the Ubuntu Server 20.04 image for the source.
[https://ubuntu.com/tutorials/how-to-install-ubuntu-on-your-raspberry-pi#2-prepare-the-sd-card](https://ubuntu.com/tutorials/how-to-install-ubuntu-on-your-raspberry-pi#2-prepare-the-sd-card)

Once you have created all 4 SD cards put them into your Raspberry Pis then complete assembly of the cluster.



## Stage 2 - Configuring the Pi nodes

Boot up each node in order then run the following steps on each node.


#### Step 1 - update cgroup settings

```bash
sudo vi /boot/firmware/cmdline.txt
cgroup_enable=memory cgroup_memory=1
```


#### Step 2 - update the OS

```bash
sudo apt update && apt upgrade -y
```


#### Step 3 - set the hostname

`sudo hostnamectl set-hostname piX` (where X is 1-4)
`sudo vi /etc/hosts` add pi0 to the ned of line 1


#### Step 4 - Give each node a fixed IP

```bash
sudo vi /etc/netplan/50-cloud-init.yaml
network:
  ethernets:
    eth0:
      addresses: [192.168.99.10X/24]
      gateway4: 192.168.99.1
      nameservers:
        addresses: [192.168.99.1]
      dhcp4: false
      dhcp6: false
  version: 2
```
(Where X is the pi number 1..4)


#### Step 5 - Update the hosts table
update /etc/hosts adding in the pi names, this will allow all the cluster nodes to address each other correctly.

`vim /etc/hosts`

```bash
127.0.0.1 localhost
192.168.99.101 pi1
192.168.99.102 pi2
192.168.99.103 pi3
192.168.99.104 pi4
```


#### Step 6 - reboot

sudo init 6
