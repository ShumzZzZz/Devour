#! /bin/bash
set -x

# turn off swap immediately and permanently
sudo swapoff -a
sudo sed -i "/ swap / s/^\(.*\)$/#\1/g" /etc/fstab

# containerd installation
cat <<EOF | sudo tee /etc/modules-load.d/k8s.conf
overlay
br_netfilter
EOF

# Load containerd modules
sudo modprobe overlay
sudo modprobe br_netfilter

cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-iptables  = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward                 = 1
EOF
sudo sysctl --system

echo "Verify that the br_netfilter, overlay modules are loaded by running the following commands:"
sudo lsmod | grep br_netfilter
sudo lsmod | grep overlay

echo "Verify that the net.bridge.bridge-nf-call-iptables, net.bridge.bridge-nf-call-ip6tables, and net.ipv4.ip_forward system variables are set to 1 in your sysctl config by running the following command:"
sysctl net.bridge.bridge-nf-call-iptables net.bridge.bridge-nf-call-ip6tables net.ipv4.ip_forward


# install containerd, runc and cni plugins
curl -OfsSL https://github.com/containerd/containerd/releases/download/v2.0.4/containerd-2.0.4-linux-amd64.tar.gz
sudo tar -C /usr/local -xzvf containerd-2.0.4-linux-amd64.tar.gz

curl -OfsSL https://raw.githubusercontent.com/containerd/containerd/main/containerd.service
sudo mv containerd.service /etc/systemd/system/containerd.service

sudo systemctl daemon-reload
sudo systemctl enable --now containerd

curl -OfsSL https://github.com/opencontainers/runc/releases/download/v1.2.6/runc.amd64
sudo install -m 755 runc.amd64 /usr/local/sbin/runc

curl -OfsSL https://github.com/containernetworking/plugins/releases/download/v1.6.2/cni-plugins-linux-amd64-v1.6.2.tgz
sudo mkdir -p /opt/cni/bin
sudo tar -C /opt/cni/bin -xzvf cni-plugins-linux-amd64-v1.6.2.tgz

sudo mkdir -p /etc/containerd
sudo containerd config default | sudo tee /etc/containerd/config.toml
sudo systemctl restart containerd

# for ubuntu 22.04
sudo apt-get update
sudo apt-get install -y apt-transport-https ca-certificates curl gpg
curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.32/deb/Release.key | sudo gpg --yes --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg

# This overwrites any existing configuration in /etc/apt/sources.list.d/kubernetes.list
echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.32/deb/ /' | sudo tee /etc/apt/sources.list.d/kubernetes.list
# after modifying, run apt-get update

# installing kubelet, kubeadm and kubectl version 1.32.3-1.1
sudo apt-get update
sudo apt-get install -y kubeadm=1.32.3-1.1 kubelet=1.32.3-1.1 kubectl=1.32.3-1.1
sudo apt-mark hold kubelet kubectl kubeadm

sudo systemctl enable --now kubelet
# ------------------ kubeadm, kubelet and kubectl install script ------------------

# set hostname and /etc/hosts
echo "The Control Plane private IPs are: 10.10.1.20"
echo "The Worker private IPs are: 10.10.1.213,10.10.1.193,10.10.1.135"
current_ip=$(hostname -I | awk '{print $1}')
echo "The current IP is: ${current_ip}"

for pair in "control-plane:10.10.1.20" "worker:10.10.1.213,10.10.1.193,10.10.1.135"; do

    prefix="${pair%%:*}"
    ips="${pair#*:}"

    IFS="," read -ra IPS <<< "$ips"

    for idx in "${!IPS[@]}"; do
        ip="${IPS[${idx}]}"
        node_name="${prefix}-${idx}"
        if [ "${ip}" == "${current_ip}" ]; then
            echo "Node Name is ${node_name}"
            if ! grep -q "export PS1=\"${node_name}> \"" /home/ubuntu/.bashrc; then
                echo "export PS1=\"${node_name}> \"" >> /home/ubuntu/.bashrc
            fi
        fi
        if ! grep -Eq "^${ip}[[:space:]]+${node_name}$" /etc/hosts; then
            echo "${ip}    ${node_name}" | sudo tee -a /etc/hosts > /dev/null
        fi
    done
done

sudo snap install aws-cli --classic
sudo snap install yq --classic

# on the current ip in the 10.10.1.20 list , run kubeadm init
if [[ ",10.10.1.20," == *",${current_ip},"* ]]; then
    # echo "#############################"
    # echo "current ip: ${current_ip}, cp_private_ips: ${cp_private_ips}"
    # echo "in control plane"
    # echo "#############################"

    # switch to ubuntu user
    su - ubuntu <<-'EOF'
    cd ${HOME}
    sudo kubeadm init --pod-network-cidr 192.168.0.0/16

    mkdir -p /home/ubuntu/.kube
    sudo cp -i /etc/kubernetes/admin.conf /home/ubuntu/.kube/config
    sudo chown $(id -u):$(id -g) /home/ubuntu/.kube/config

    sudo kubeadm token create --print-join-command | aws s3 cp - s3://feast-shumin/join-command-2025-04-24T22:50:13Z.sh --region us-west-2

    kubectl create -f https://raw.githubusercontent.com/projectcalico/calico/v3.29.3/manifests/tigera-operator.yaml
    curl -fsSLO https://raw.githubusercontent.com/projectcalico/calico/v3.29.3/manifests/custom-resources.yaml

    echo "modifying the custom-resources.yaml file"
    yq ea 'select(.kind == "Installation") |= (.spec.calicoNetwork.ipPools[] |= select(.name == "default-ipv4-ippool") * {"encapsulation": "IPIP"})' -i custom-resources.yaml

    echo "executing kubectl apply -f custom-resources.yaml"
    kubectl apply -f custom-resources.yaml

    echo "installing calicoctl"
    cd /usr/local/bin
    sudo curl -fsSL https://github.com/projectcalico/calico/releases/download/v3.29.3/calicoctl-linux-amd64 -o calicoctl
    sudo chmod +x ./calicoctl
    export DATASTORE_TYPE=kubernetes
    export KUBECONFIG=${HOME}/.kube/config

    echo "installing helm"
    cd ${HOME}
    curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3
    chmod 700 get_helm.sh
    ./get_helm.sh

    helm repo add aws-ebs-csi-driver https://kubernetes-sigs.github.io/aws-ebs-csi-driver
    helm repo add kyverno https://kyverno.github.io/kyverno/
	helm repo update

	helm upgrade --install aws-ebs-csi-driver \
		--namespace kube-system \
		aws-ebs-csi-driver/aws-ebs-csi-driver

	# kubectl get pods -n kube-system -l app.kubernetes.io/name=aws-ebs-csi-driver
	EOF

    # if the node is a worker, run kubeadm join
else
    # echo "#############################"
    # echo "current ip: ${current_ip}, cp_private_ips: 10.10.1.20"
    # echo "in worker"
    # echo "#############################"
    su - ubuntu <<-'EOF'
    cd ${HOME}
    until aws s3 ls s3://feast-shumin/join-command-2025-04-24T22:50:13Z.sh --region us-west-2; do
      echo "Waiting for join-command.sh..."
      sleep 10
    done
    aws s3 cp s3://feast-shumin/join-command-2025-04-24T22:50:13Z.sh /home/ubuntu/join-command.sh --region us-west-2
    chmod +x /home/ubuntu/join-command.sh
    sudo bash /home/ubuntu/join-command.sh
	EOF
fi
