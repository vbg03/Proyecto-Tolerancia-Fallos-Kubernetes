#!/bin/bash

echo "🔧 === RECONSTRUYENDO MICROSERVICIO DE USUARIOS ==="
echo ""

# Colores
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

cd /vagrant

# 1. Verificar que el archivo views.py esté correcto
echo "${YELLOW}📝 Verificando users/views.py...${NC}"
if grep -q "app.register_blueprint(user_controller)" microUsers/users/views.py; then
    echo "${GREEN}✅ Blueprint ya está registrado${NC}"
else
    echo "${RED}❌ Blueprint NO está registrado${NC}"
    echo "${YELLOW}Agregando registro del blueprint...${NC}"
    
    # Hacer backup
    cp microUsers/users/views.py microUsers/users/views.py.backup
    
    # Agregar el registro del blueprint antes del if __name__
    sed -i "/if __name__ == '__main__':/i # Registrar el blueprint\napp.register_blueprint(user_controller)\n" microUsers/users/views.py
    
    echo "${GREEN}✅ Blueprint agregado${NC}"
fi

echo ""

# 2. Reconstruir la imagen Docker
echo "${YELLOW}🐳 Reconstruyendo imagen Docker...${NC}"
eval $(minikube docker-env)
docker build -t users-api:latest ./microUsers

if [ $? -ne 0 ]; then
    echo "${RED}❌ Error al construir la imagen${NC}"
    exit 1
fi

echo "${GREEN}✅ Imagen construida exitosamente${NC}"
echo ""

# 3. Reiniciar el deployment
echo "${YELLOW}🔄 Reiniciando deployment...${NC}"
kubectl rollout restart deployment/users-api

echo "Esperando que el rollout se complete..."
kubectl rollout status deployment/users-api --timeout=120s

if [ $? -ne 0 ]; then
    echo "${RED}❌ Error en el rollout${NC}"
    echo "Logs del pod:"
    kubectl logs -l app=users-api --tail=30
    exit 1
fi

echo "${GREEN}✅ Deployment reiniciado${NC}"
echo ""

# 4. Esperar a que los pods estén listos
echo "${YELLOW}⏳ Esperando a que los pods estén listos...${NC}"
sleep 10

# 5. Verificar conectividad
echo ""
echo "${YELLOW}🧪 Probando conectividad...${NC}"
echo ""

echo "1️⃣ Health check:"
curl -s http://192.168.100.10:5002/health
echo ""
echo ""

echo "2️⃣ GET /api/users:"
curl -s http://192.168.100.10:5002/api/users | head -c 200
echo ""
echo ""

echo "3️⃣ Probando login (usuario: juan, password: 123):"
curl -s -X POST http://192.168.100.10:5002/api/login \
  -H "Content-Type: application/json" \
  -d '{"username":"juan","password":"123"}' | jq . 2>/dev/null || curl -s -X POST http://192.168.100.10:5002/api/login -H "Content-Type: application/json" -d '{"username":"juan","password":"123"}'
echo ""
echo ""

# 6. Mostrar estado final
echo "${GREEN}=== ✅ RECONSTRUCCIÓN COMPLETADA ===${NC}"
echo ""
echo "📊 Estado de los pods:"
kubectl get pods -l app=users-api
echo ""
echo "🌐 URLs de prueba:"
echo "  curl http://192.168.100.10:5002/health"
echo "  curl http://192.168.100.10:5002/api/users"
echo ""
echo "🌐 Frontend:"
echo "  http://192.168.100.10:8080"
echo ""

# 7. Verificar logs si hay errores
PODS_READY=$(kubectl get pods -l app=users-api -o jsonpath='{.items[*].status.containerStatuses[0].ready}' | grep -o "true" | wc -l)
TOTAL_PODS=$(kubectl get pods -l app=users-api --no-headers | wc -l)

if [ "$PODS_READY" -lt "$TOTAL_PODS" ]; then
    echo "${RED}⚠️  Algunos pods no están listos. Logs:${NC}"
    kubectl logs -l app=users-api --tail=20
fi