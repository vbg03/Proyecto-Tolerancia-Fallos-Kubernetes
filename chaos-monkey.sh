#!/bin/bash

# 🐵 CHAOS MONKEY SIMPLE PARA KUBERNETES
# Este script elimina pods aleatoriamente para probar tolerancia a fallos

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
NC='\033[0m'

echo ""
echo "╔═══════════════════════════════════════════════════════╗"
echo "║      🐵 CHAOS MONKEY - KUBERNETES EDITION 🐵        ║"
echo "╚═══════════════════════════════════════════════════════╝"
echo ""

# Configuración
NAMESPACE="default"
TARGET_APPS=("users-api" "products-api" "orders-api")
CHAOS_INTERVAL=30  # Segundos entre ataques
MAX_ATTACKS=10     # Número máximo de ataques

# Función para matar un pod aleatorio
kill_random_pod() {
    local app=${TARGET_APPS[$RANDOM % ${#TARGET_APPS[@]}]}
    
    # Obtener pods del app
    local pods=($(kubectl get pods -n $NAMESPACE -l app=$app -o jsonpath='{.items[*].metadata.name}'))
    
    if [ ${#pods[@]} -eq 0 ]; then
        echo -e "${YELLOW}⚠️  No hay pods disponibles para $app${NC}"
        return 1
    fi
    
    # Seleccionar pod aleatorio
    local target_pod=${pods[$RANDOM % ${#pods[@]}]}
    
    echo ""
    echo -e "${RED}💥 CHAOS MONKEY ATTACK!${NC}"
    echo -e "${RED}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "  🎯 Target: ${MAGENTA}$target_pod${NC}"
    echo -e "  📦 App: ${BLUE}$app${NC}"
    echo -e "  ⏰ Time: $(date '+%Y-%m-%d %H:%M:%S')"
    echo -e "${RED}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    
    # Eliminar el pod
    kubectl delete pod $target_pod -n $NAMESPACE --force --grace-period=0 2>/dev/null
    
    echo -e "${YELLOW}⚡ Pod eliminado. Kubernetes debería recrearlo...${NC}"
    
    # Esperar un poco y mostrar el estado
    sleep 5
    echo ""
    echo -e "${GREEN}📊 Estado de pods de $app:${NC}"
    kubectl get pods -n $NAMESPACE -l app=$app
}

# Función para monitorear pods
monitor_pods() {
    echo ""
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BLUE}  📊 ESTADO DEL CLUSTER${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    
    for app in "${TARGET_APPS[@]}"; do
        local total=$(kubectl get pods -n $NAMESPACE -l app=$app --no-headers | wc -l)
        local running=$(kubectl get pods -n $NAMESPACE -l app=$app --no-headers | grep Running | wc -l)
        echo -e "  ${MAGENTA}$app${NC}: $running/$total running"
    done
    
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
}

# Modo continuo
continuous_chaos() {
    echo ""
    echo -e "${YELLOW}🎮 Iniciando modo CAOS CONTINUO...${NC}"
    echo -e "${YELLOW}   Intervalo: ${CHAOS_INTERVAL}s | Max ataques: ${MAX_ATTACKS}${NC}"
    echo -e "${YELLOW}   Presiona Ctrl+C para detener${NC}"
    echo ""
    
    local attack_count=0
    
    while [ $attack_count -lt $MAX_ATTACKS ]; do
        monitor_pods
        kill_random_pod
        
        attack_count=$((attack_count + 1))
        echo ""
        echo -e "${GREEN}✓ Ataque $attack_count/$MAX_ATTACKS completado${NC}"
        
        if [ $attack_count -lt $MAX_ATTACKS ]; then
            echo -e "${YELLOW}⏳ Esperando ${CHAOS_INTERVAL}s para el próximo ataque...${NC}"
            sleep $CHAOS_INTERVAL
        fi
    done
    
    echo ""
    echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${GREEN}  🎉 CHAOS MONKEY COMPLETADO${NC}"
    echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    monitor_pods
}

# Modo ataque único
single_attack() {
    echo -e "${YELLOW}🎯 Modo: Ataque único${NC}"
    monitor_pods
    kill_random_pod
    
    echo ""
    echo -e "${GREEN}✓ Ataque completado${NC}"
    
    sleep 10
    monitor_pods
}

# Modo targeted (atacar app específica)
targeted_attack() {
    echo ""
    echo "Aplicaciones disponibles:"
    for i in "${!TARGET_APPS[@]}"; do
        echo "  $((i+1)). ${TARGET_APPS[$i]}"
    done
    echo ""
    read -p "Selecciona la app a atacar (1-${#TARGET_APPS[@]}): " choice
    
    if [ $choice -ge 1 ] && [ $choice -le ${#TARGET_APPS[@]} ]; then
        local target_app=${TARGET_APPS[$((choice-1))]}
        
        echo ""
        read -p "¿Cuántos pods eliminar? " num_pods
        
        for i in $(seq 1 $num_pods); do
            echo ""
            echo -e "${YELLOW}Ataque $i/$num_pods${NC}"
            
            local pods=($(kubectl get pods -n $NAMESPACE -l app=$target_app -o jsonpath='{.items[*].metadata.name}'))
            
            if [ ${#pods[@]} -eq 0 ]; then
                echo -e "${RED}No hay más pods disponibles${NC}"
                break
            fi
            
            local pod=${pods[0]}
            echo -e "${RED}💥 Eliminando $pod${NC}"
            kubectl delete pod $pod -n $NAMESPACE --force --grace-period=0
            
            sleep 2
        done
        
        echo ""
        monitor_pods
    else
        echo -e "${RED}Opción inválida${NC}"
    fi
}

# Estadísticas
show_stats() {
    echo ""
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BLUE}  📈 ESTADÍSTICAS DEL CLUSTER${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    
    for app in "${TARGET_APPS[@]}"; do
        echo -e "${MAGENTA}$app:${NC}"
        kubectl get pods -n $NAMESPACE -l app=$app -o custom-columns=\
NAME:.metadata.name,\
STATUS:.status.phase,\
RESTARTS:.status.containerStatuses[0].restartCount,\
AGE:.metadata.creationTimestamp
        echo ""
    done
    
    echo -e "${BLUE}Eventos recientes:${NC}"
    kubectl get events -n $NAMESPACE --sort-by='.lastTimestamp' | tail -10
}

# Menú principal
menu() {
    clear
    echo ""
    echo "╔═══════════════════════════════════════════════════════╗"
    echo "║      🐵 CHAOS MONKEY - KUBERNETES EDITION 🐵        ║"
    echo "╚═══════════════════════════════════════════════════════╝"
    echo ""
    echo "  1. 🔥 Modo Caos Continuo (elimina pods cada ${CHAOS_INTERVAL}s)"
    echo "  2. 🎯 Ataque Único (mata 1 pod aleatorio)"
    echo "  3. 🎪 Ataque Dirigido (selecciona app y cantidad)"
    echo "  4. 📊 Ver Estado del Cluster"
    echo "  5. 📈 Ver Estadísticas y Eventos"
    echo "  6. ⚙️  Configuración"
    echo "  7. 🚪 Salir"
    echo ""
    echo "────────────────────────────────────────────────────────"
    read -p "Selecciona una opción: " choice
    
    case $choice in
        1) continuous_chaos ;;
        2) single_attack ;;
        3) targeted_attack ;;
        4) monitor_pods ;;
        5) show_stats ;;
        6)
            echo ""
            read -p "Intervalo entre ataques (segundos) [$CHAOS_INTERVAL]: " new_interval
            [ ! -z "$new_interval" ] && CHAOS_INTERVAL=$new_interval
            
            read -p "Máximo de ataques [$MAX_ATTACKS]: " new_max
            [ ! -z "$new_max" ] && MAX_ATTACKS=$new_max
            
            echo -e "${GREEN}✓ Configuración actualizada${NC}"
            ;;
        7) exit 0 ;;
        *) echo -e "${RED}Opción inválida${NC}" ;;
    esac
    
    echo ""
    read -p "Presiona Enter para continuar..."
    menu
}

# Verificar kubectl
if ! command -v kubectl &> /dev/null; then
    echo -e "${RED}❌ kubectl no está instalado${NC}"
    exit 1
fi

# Verificar conectividad
if ! kubectl cluster-info &> /dev/null; then
    echo -e "${RED}❌ No se puede conectar al cluster${NC}"
    exit 1
fi

# Trap para cleanup
trap 'echo ""; echo -e "${YELLOW}🛑 Chaos Monkey detenido${NC}"; exit 0' INT TERM

# Iniciar menú
menu