#!/bin/bash

echo "=== Actualizando sistema ==="
sudo apt-get update
sudo apt-get upgrade -y

echo "=== Instalando Docker ==="
sudo apt-get install -y apt-transport-https ca-certificates curl software-properties-common
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
echo "deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt-get update
sudo apt-get install -y docker-ce docker-ce-cli containerd.io
sudo usermod -aG docker vagrant

echo "=== Instalando kubectl ==="
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl

echo "=== Instalando Minikube ==="
curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64
sudo install minikube-linux-amd64 /usr/local/bin/minikube

echo "=== Instalando Helm ==="
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

echo "=== Iniciando Minikube ==="
# Configuración óptima: 7GB RAM, 3 CPUs (deja recursos para sistema)
sudo -u vagrant minikube start --driver=docker --memory=7168 --cpus=3

echo "=== Habilitando addons de Minikube ==="
sudo -u vagrant minikube addons enable metrics-server
sudo -u vagrant minikube addons enable ingress

echo "=== Instalación completada ==="