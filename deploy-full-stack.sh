#!/bin/bash

echo "🚀 === DESPLIEGUE COMPLETO CON ISTIO + MONITOREO + CHAOS ==="
echo ""

# Colores
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Limpiar instalación anterior
echo "${YELLOW}🧹 Limpiando instalación anterior...${NC}"
minikube delete
sleep 5

# Iniciar Minikube
echo "${YELLOW}🚀 Iniciando Minikube...${NC}"
minikube start --driver=docker --memory=7168 --cpus=3

# Addons
echo "${YELLOW}✨ Habilitando addons...${NC}"
minikube addons enable metrics-server
minikube addons enable ingress

# Instalar Istio
echo "${YELLOW}📦 Instalando Istio...${NC}"
cd ~
if [ ! -d "istio-1.24.0" ]; then
    curl -L https://istio.io/downloadIstio | sh -
fi
cd istio-1.24.0
export PATH=$PWD/bin:$PATH

istioctl install --set profile=demo -y
kubectl label namespace default istio-injection=enabled --overwrite

# Construir imágenes
cd /vagrant
echo "${YELLOW}🐳 Construyendo imágenes Docker...${NC}"
eval $(minikube docker-env)

docker build -t users-api:latest ./microUsers
docker build -t products-api:latest ./microProductos
docker build -t orders-api:latest ./microOrders
docker build -t frontend:latest ./frontend

# Desplegar aplicación
echo "${YELLOW}☸️ Desplegando aplicación...${NC}"
kubectl apply -f k8s/base/mysql-deployment.yaml
kubectl wait --for=condition=ready pod -l app=mysql --timeout=120s

kubectl apply -f k8s/base/users-deployment.yaml
kubectl apply -f k8s/base/products-deployment.yaml
kubectl apply -f k8s/base/orders-deployment.yaml
kubectl apply -f k8s/base/frontend-deployment.yaml

echo "${YELLOW}⏳ Esperando pods...${NC}"
sleep 30

# Aplicar políticas de tolerancia a fallos
echo "${YELLOW}🛡️ Aplicando políticas de tolerancia...${NC}"
kubectl apply -f k8s/base/circuit-breaker.yaml
kubectl apply -f k8s/base/retry-policy.yaml
kubectl apply -f k8s/base/hpa.yaml

# Instalar Prometheus y Grafana
echo "${YELLOW}📊 Instalando Prometheus y Grafana...${NC}"
kubectl apply -f https://raw.githubusercontent.com/istio/istio/release-1.20/samples/addons/prometheus.yaml
kubectl apply -f https://raw.githubusercontent.com/istio/istio/release-1.20/samples/addons/grafana.yaml
kubectl apply -f https://raw.githubusercontent.com/istio/istio/release-1.20/samples/addons/kiali.yaml

echo "${YELLOW}⏳ Esperando monitoreo...${NC}"
kubectl wait --for=condition=available --timeout=300s deployment/prometheus -n istio-system
kubectl wait --for=condition=available --timeout=300s deployment/grafana -n istio-system
kubectl wait --for=condition=available --timeout=300s deployment/kiali -n istio-system

# Instalar Litmus Chaos
echo "${YELLOW}🧪 Instalando Litmus Chaos...${NC}"
kubectl create namespace litmus 2>/dev/null || true
helm repo add litmuschaos https://litmuschaos.github.io/litmus-helm/ 2>/dev/null || true
helm repo update

helm install chaos litmuschaos/litmus \
  --namespace=litmus \
  --set portal.frontend.service.type=NodePort \
  --set portal.frontend.service.nodePort=30091

echo "${YELLOW}⏳ Esperando Litmus...${NC}"
kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=litmus --namespace=litmus --timeout=300s

# Instalar experimentos de caos
kubectl apply -f https://hub.litmuschaos.io/api/chaos/master?file=charts/generic/experiments.yaml -n default

echo ""
echo "${GREEN}✅ ============================================${NC}"
echo "${GREEN}   INSTALACIÓN COMPLETADA EXITOSAMENTE${NC}"
echo "${GREEN}============================================${NC}"
echo ""
echo "📊 Estado de los servicios:"
kubectl get pods --all-namespaces | grep -E "users-api|products-api|orders-api|frontend|prometheus|grafana|kiali|litmus"
echo ""
echo "🌐 URLs de acceso:"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "Frontend:    http://192.168.100.10:$(kubectl get svc frontend -o jsonpath='{.spec.ports[0].nodePort}')"
echo "Grafana:     http://192.168.100.10:30001"
echo "Prometheus:  http://192.168.100.10:30002"
echo "Kiali:       http://192.168.100.10:30003"
echo "Litmus:      http://192.168.100.10:30091"
echo ""
echo "Para abrir los dashboards, ejecuta en OTRA terminal:"
echo ""
echo "# Grafana"
echo "kubectl port-forward -n istio-system svc/grafana 3000:3000 --address 0.0.0.0 &"
echo ""
echo "# Prometheus"
echo "kubectl port-forward -n istio-system svc/prometheus 9090:9090 --address 0.0.0.0 &"
echo ""
echo "# Kiali"
echo "kubectl port-forward -n istio-system svc/kiali 20001:20001 --address 0.0.0.0 &"
echo ""
echo "# Litmus"
echo "kubectl port-forward -n litmus svc/chaos-litmus-frontend-service 9091:9091 --address 0.0.0.0 &"
echo ""
echo "Credenciales de Litmus:"
echo "  Usuario: admin"
echo "  Contraseña: Admin*1234"
echo ""
echo "${GREEN}¡Listo para empezar! 🎉${NC}"