#!/bin/bash

echo "=== 🧪 Pruebas de Tolerancia a Fallos ==="
echo ""

# Colores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Función para mostrar estado de pods
show_pods() {
    echo ""
    echo "📊 Estado actual de los pods:"
    kubectl get pods -o wide
    echo ""
}

# Función para esperar
wait_seconds() {
    echo "⏳ Esperando $1 segundos..."
    sleep $1
}

# PRUEBA 1: Eliminar un pod y ver la auto-recuperación (Self-healing)
test_self_healing() {
    echo ""
    echo "${YELLOW}=== PRUEBA 1: Self-Healing (Auto-recuperación) ===${NC}"
    echo "Eliminando un pod de users-api para simular un fallo..."
    
    show_pods
    
    POD_NAME=$(kubectl get pods -l app=users-api -o jsonpath='{.items[0].metadata.name}')
    echo "🔴 Eliminando pod: $POD_NAME"
    kubectl delete pod $POD_NAME
    
    wait_seconds 5
    
    echo "✅ Kubernetes debería haber creado un nuevo pod automáticamente:"
    show_pods
    
    echo "${GREEN}✓ Self-healing completado${NC}"
}

# PRUEBA 2: Simular alta carga y ver HPA en acción
test_hpa() {
    echo ""
    echo "${YELLOW}=== PRUEBA 2: Horizontal Pod Autoscaler (HPA) ===${NC}"
    echo "Generando carga en users-api..."
    
    # Verificar si HPA está configurado
    kubectl get hpa
    
    echo ""
    echo "Generando 100 requests en paralelo..."
    for i in {1..100}; do
        curl -s http://192.168.100.10:5002/api/users > /dev/null &
    done
    
    wait_seconds 30
    
    echo "📈 Estado del HPA:"
    kubectl get hpa
    show_pods
    
    echo "${GREEN}✓ Prueba de HPA completada${NC}"
}

# PRUEBA 3: Simular fallo de base de datos
test_database_failure() {
    echo ""
    echo "${YELLOW}=== PRUEBA 3: Fallo de Base de Datos ===${NC}"
    echo "Simulando fallo de MySQL..."
    
    echo "🔴 Escalando MySQL a 0 réplicas..."
    kubectl scale deployment mysql --replicas=0
    
    wait_seconds 5
    show_pods
    
    echo "Intentando hacer un request..."
    curl -s http://192.168.100.10:5002/api/users || echo "${RED}✗ Servicio no disponible (esperado)${NC}"
    
    wait_seconds 10
    
    echo ""
    echo "🟢 Restaurando MySQL..."
    kubectl scale deployment mysql --replicas=1
    
    wait_seconds 30
    
    echo "Esperando a que MySQL esté listo..."
    kubectl wait --for=condition=ready pod -l app=mysql --timeout=60s
    
    show_pods
    
    echo "Intentando hacer un request nuevamente..."
    curl -s http://192.168.100.10:5002/api/users && echo "${GREEN}✓ Servicio restaurado${NC}"
}

# PRUEBA 4: Circuit Breaker con Istio
test_circuit_breaker() {
    echo ""
    echo "${YELLOW}=== PRUEBA 4: Circuit Breaker ===${NC}"
    
    # Verificar si el circuit breaker está configurado
    kubectl get destinationrule users-api-circuit-breaker -o yaml | grep -A 10 "outlierDetection"
    
    echo ""
    echo "Generando 50 requests fallidos..."
    for i in {1..50}; do
        curl -s http://192.168.100.10:5002/api/users/99999 > /dev/null &
    done
    wait
    
    wait_seconds 5
    
    echo "${GREEN}✓ Circuit breaker debería haberse activado${NC}"
    echo "Revisa Grafana/Kiali para ver las métricas"
}

# PRUEBA 5: Retry Policy
test_retry_policy() {
    echo ""
    echo "${YELLOW}=== PRUEBA 5: Retry Policy ===${NC}"
    
    # Verificar configuración de retry
    kubectl get virtualservice users-api-retry -o yaml | grep -A 5 "retries"
    
    echo ""
    echo "Eliminando temporalmente un pod para forzar retries..."
    POD_NAME=$(kubectl get pods -l app=users-api -o jsonpath='{.items[0].metadata.name}')
    kubectl delete pod $POD_NAME &
    
    # Hacer request mientras se elimina
    sleep 2
    echo "Haciendo request (debería retryar automáticamente)..."
    curl -s http://192.168.100.10:5002/api/users && echo "${GREEN}✓ Request exitoso gracias a retry${NC}"
    
    wait
}

# PRUEBA 6: Tolerancia a fallos de red
test_network_failure() {
    echo ""
    echo "${YELLOW}=== PRUEBA 6: Simulación de Fallo de Red ===${NC}"
    echo "Esta prueba requiere Chaos Mesh o similar"
    echo "Por ahora, puedes simular manualmente eliminando pods"
    echo ""
    echo "Comando manual:"
    echo "  kubectl delete pod -l app=products-api --force --grace-period=0"
}

# Menú principal
menu() {
    echo ""
    echo "=== 🧪 Menú de Pruebas de Tolerancia a Fallos ==="
    echo ""
    echo "1. Self-Healing (Auto-recuperación)"
    echo "2. HPA (Escalado automático)"
    echo "3. Fallo de Base de Datos"
    echo "4. Circuit Breaker"
    echo "5. Retry Policy"
    echo "6. Todas las pruebas"
    echo "7. Ver logs de un servicio"
    echo "8. Ver métricas en Grafana"
    echo "9. Salir"
    echo ""
    read -p "Selecciona una opción: " choice
    
    case $choice in
        1) test_self_healing ;;
        2) test_hpa ;;
        3) test_database_failure ;;
        4) test_circuit_breaker ;;
        5) test_retry_policy ;;
        6) 
            test_self_healing
            test_hpa
            test_database_failure
            test_circuit_breaker
            test_retry_policy
            ;;
        7)
            echo "Servicios disponibles:"
            echo "1. users-api"
            echo "2. products-api"
            echo "3. orders-api"
            echo "4. frontend"
            read -p "Selecciona: " svc
            case $svc in
                1) kubectl logs -l app=users-api --tail=50 ;;
                2) kubectl logs -l app=products-api --tail=50 ;;
                3) kubectl logs -l app=orders-api --tail=50 ;;
                4) kubectl logs -l app=frontend --tail=50 ;;
            esac
            ;;
        8)
            echo ""
            echo "🌐 Accede a Grafana en: http://192.168.100.10:3000"
            echo "🌐 Accede a Prometheus en: http://192.168.100.10:9090"
            echo "🌐 Accede a Kiali en: http://192.168.100.10:20001"
            echo ""
            ;;
        9) exit 0 ;;
        *) echo "Opción inválida" ;;
    esac
    
    menu
}

# Iniciar
echo "Este script te ayudará a probar los patrones de tolerancia a fallos"
echo "Asegúrate de tener Grafana y Prometheus abiertos para ver las métricas"
echo ""

menu
