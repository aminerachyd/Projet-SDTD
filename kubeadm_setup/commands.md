# Commands for setting up a minimal kubernetes cluster :

Before anything, we need to install docker on both the nodes :

```
sudo apt-get update
```

```
sudo apt-get install -y apt-transport-https ca-certificates curl gnupg lsb-release
```

```
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/debian \
  $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
```

```
sudo apt-get update
```

```
sudo apt-get install -y --allow-unauthenticated docker-ce docker-ce-cli containerd.io
```

Then we add the current user to docker group and reboot :

```
sudo usermod -aG docker $USER
```

```
sudo reboot
```

Then we tell the system to use the docker runtime for running its pods :

```
sudo mkdir /etc/docker
```

```
cat <<EOF | sudo tee /etc/docker/daemon.json
{
  "exec-opts": ["native.cgroupdriver=systemd"],
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "100m"
  },
  "storage-driver": "overlay2"
}
EOF
```

```
sudo systemctl enable docker
```

```
sudo systemctl daemon-reload
```

```
sudo systemctl restart docker
```

After that, we install **kubeadm** on both master and worker nodes.

## On both the nodes :

```
cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
EOF
```

```
sudo sysctl --system
```

```
curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add -
```

```
cat <<EOF | sudo tee /etc/apt/sources.list.d/kubernetes.list
deb https://apt.kubernetes.io/ kubernetes-xenial main
EOF
```

```
sudo apt-get update
```

```
sudo apt-get install -y kubelet kubeadm kubectl
```

```
sudo apt-mark hold kubelet kubeadm kubectl
```

```
sudo swapoff -a
```

```
sudo reboot
```

### On the master node :

If everything goes well, run command :

```
sudo kubeadm init
```

```
mkdir -p $HOME/.kube
```

```
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
```

```
sudo chown $(id -u):$(id -g) $HOME/.kube/config
```

### On the worker node :

If everything goes well, run command :

```
sudo kubeadm join --token <token> <master-ip>:<master-port> --discovery-token-ca-cert-hash sha256:<hash>
```

Retrieve the token with the command (on the **MASTER**):

```
kubeadm token list
```

If there is no token in the list, create one :

```
kubeadm token create
```

The master port is 6443  
Retrieve --discovery-token-ca-cert-hash with the command (on the **MASTER**) :

```
openssl x509 -pubkey -in /etc/kubernetes/pki/ca.crt | openssl rsa -pubin -outform der 2>/dev/null | openssl dgst -sha256 -hex | sed 's/^.* //'
```

### On the master node :

After initialing the master node and joining the worker nodes, run the command (networking add-on for Kubernetes) :

```
kubectl apply -f "https://cloud.weave.works/k8s/net?k8s-version=$(kubectl version | base64 | tr -d '\n')"
```

# Connecting to the cluster :

### Still a WIP (connexion from the same network)

You just need to copy the ~/.kube/config file from the master node to the machine you want to use kubectl on with the external cluster, [check here](https://medium.com/@raj10x/configure-local-kubectl-to-access-remote-kubernetes-cluster-ee78feff2d6d)
