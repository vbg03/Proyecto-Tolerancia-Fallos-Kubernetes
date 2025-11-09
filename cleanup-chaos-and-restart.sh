#!/bin/bash

echo "🧹 === LIMPIEZA DE EXPERIMENTOS DE CAOS Y REINICIO ==="
echo ""

# Colores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# 1. Detener todos los experimentos de caos
echo "${YELLOW}🛑 Deteniendo experimentos de caos activos...${NC}"
kubectl delete chaosengines --all -n default 2>/dev/null || echo "No hay experimentos activos"

# 2. Verificar y limpiar políticas de Istio problemáticas
echo ""
echo "${YELLOW}🔍 Verificando políticas de Istio...${NC}"

# Listar todas las políticas
echo "DestinationRules actuales:"
kubectl get destinationrules

echo ""
echo "VirtualServices actuales:"
kubectl get virtualservices

# 3. Reiniciar el deployment de users-api
echo ""
echo "${YELLOW}🔄 Reiniciando users-api...${NC}"
kubectl rollout restart deployment/users-api

echo "Esperando que el deployment se complete..."
kubectl rollout status deployment/users-api --timeout=120s

# 4. Verificar conectividad
echo ""
echo "${YELLOW}✅ Verificando conectividad...${NC}"

# Esperar un poco más para asegurar que los pods estén listos
sleep 10

# Obtener el nombre del pod
POD_NAME=$(kubectl get pod -l app=users-api -o jsonpath='{.items[0].metadata.name}')

if [ -z "$POD_NAME" ]; then
    echo "${RED}❌ No se encontró ningún pod de users-api${NC}"
    exit 1
fi

echo "Pod encontrado: $POD_NAME"

# Verificar salud interna
echo ""
echo "Verificando endpoint /health:"
kubectl exec -it $POD_NAME -- curl -s localhost:5002/health
echo ""

# Verificar endpoint /api/users
echo ""
echo "Verificando endpoint /api/users:"
kubectl exec -it $POD_NAME -- curl -s localhost:5002/api/users | head -c 200
echo ""

# 5. Verificar el servicio
echo ""
echo "${YELLOW}🔍 Verificando servicio de Kubernetes...${NC}"
kubectl get svc users-api

# Obtener el NodePort si existe
NODEPORT=$(kubectl get svc users-api-external -o jsonpath='{.spec.ports[0].nodePort}' 2>/dev/null)

if [ ! -z "$NODEPORT" ]; then
    echo ""
    echo "Servicio expuesto en NodePort: $NODEPORT"
    echo "URL: http://192.168.100.10:$NODEPORT"
fi

# 6. Probar conectividad externa
echo ""
echo "${YELLOW}🌐 Probando conectividad externa...${NC}"

# Desde dentro de minikube
minikube ssh "curl -s http://users-api:5002/health" && echo "${GREEN}✓ Conectividad interna OK${NC}" || echo "${RED}✗ Problema de conectividad interna${NC}"

# 7. Verificar logs para errores
echo ""
echo "${YELLOW}📋 Últimas líneas de logs:${NC}"
kubectl logs -l app=users-api --tail=20

# 8. Verificar si hay sidecars de Istio
echo ""
echo "${YELLOW}🔍 Verificando sidecars de Istio...${NC}"
kubectl get pods -l app=users-api -o jsonpath='{.items[*].spec.containers[*].name}'
echo ""

# 9. Estado final
echo ""
echo "${GREEN}=== ✅ LIMPIEZA COMPLETADA ===${NC}"
echo ""
echo "Estado de los pods:"
kubectl get pods -l app=users-api -o wide
echo ""
echo "Si el problema persiste, ejecuta:"
echo "  kubectl logs -l app=users-api -f"
echo ""
echo "O reinicia completamente la aplicación:"
echo "  kubectl delete pod -l app=users-api"
echo ""