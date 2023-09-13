#!/bin/bash -ex

# aws-cli
sudo apt update
sudo apt install python3-pip -y
sudo pip3 install --upgrade awscli

# aws-iam-authenticator
curl -Lo aws-iam-authenticator https://github.com/kubernetes-sigs/aws-iam-authenticator/releases/download/v0.6.11/aws-iam-authenticator_0.6.11_linux_amd64
sudo chown root:root aws-iam-authenticator
sudo chmod +x aws-iam-authenticator
sudo mv aws-iam-authenticator /usr/local/bin/

# kubectl
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
sudo chown root:root kubectl
sudo chmod +x kubectl
sudo mv kubectl /usr/local/bin/

# helm
curl -LO "https://get.helm.sh/helm-v3.12.3-linux-amd64.tar.gz"
tar -zxvf helm-v3.12.3-linux-amd64.tar.gz
sudo chown root:root linux-amd64/helm
sudo chmod +x linux-amd64/helm
sudo mv linux-amd64/helm /usr/local/bin/

# export kubeconfig
# aws eks update-kubeconfig --region <region> --name <project>-<env>-cluster


