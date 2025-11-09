#!/bin/bash

echo "🔧 === REINICIO COMPLETO DEL SERVICIO DE USUARIOS ==="
echo ""

# Colores
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# 1. Eliminar TODAS las políticas de Istio relacionadas con users-api
echo "${YELLOW}🗑️ Eliminando políticas de Istio...${NC}"
kubectl delete destinationrule users-api-circuit-breaker 2>/dev/null || true
kubectl delete virtualservice users-api-retry 2>/dev/null || true

# 2. Eliminar el deployment y servicio
echo "${YELLOW}🗑️ Eliminando deployment y servicio...${NC}"
kubectl delete deployment users-api
kubectl delete svc users-api
kubectl delete svc users-api-external 2>/dev/null || true

# Esperar a que todo se elimine
sleep 5

# 3. Reconstruir la imagen Docker
echo "${YELLOW}🐳 Reconstruyendo imagen Docker...${NC}"
cd /vagrant
eval $(minikube docker-env)
docker build -t users-api:latest ./microUsers

# 4. Redesplegar
echo "${YELLOW}☸️ Redesplegando servicio...${NC}"
kubectl apply -f k8s/base/users-deployment.yaml

# 5. Esperar a que esté listo
echo "${YELLOW}⏳ Esperando a que el servicio esté listo...${NC}"
kubectl wait --for=condition=ready pod -l app=users-api --timeout=120s

# 6. Exponer el servicio como NodePort
echo "${YELLOW}🌐 Exponiendo servicio...${NC}"
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Service
metadata:
  name: users-api-external
spec:
  type: NodePort
  selector:
    app: users-api
  ports:
  - port: 5002
    targetPort: 5002
    nodePort: 30002
EOF

# 7. Verificar
echo ""
echo "${GREEN}=== ✅ REINICIO COMPLETADO ===${NC}"
echo ""
kubectl get pods -l app=users-api
kubectl get svc users-api
kubectl get svc users-api-external
echo ""
echo "Prueba el servicio:"
echo "  curl http://192.168.100.10:30002/health"
echo "  curl http://192.168.100.10:30002/api/users"
echo ""