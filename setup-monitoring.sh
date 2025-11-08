#!/bin/bash

echo "=== Configurando Monitoreo con Prometheus y Grafana ==="

# Verificar que Istio esté instalado
if ! kubectl get namespace istio-system &> /dev/null; then
    echo "❌ ERROR: Istio no está instalado. Instálalo primero."
    exit 1
fi

echo "✅ Istio detectado"

# Instalar Prometheus
echo "📊 Instalando Prometheus..."
kubectl apply -f https://raw.githubusercontent.com/istio/istio/release-1.20/samples/addons/prometheus.yaml

# Esperar a que Prometheus esté listo
echo "⏳ Esperando a que Prometheus esté listo..."
kubectl wait --for=condition=available --timeout=300s deployment/prometheus -n istio-system

# Instalar Grafana
echo "📈 Instalando Grafana..."
kubectl apply -f https://raw.githubusercontent.com/istio/istio/release-1.20/samples/addons/grafana.yaml

# Esperar a que Grafana esté listo
echo "⏳ Esperando a que Grafana esté listo..."
kubectl wait --for=condition=available --timeout=300s deployment/grafana -n istio-system

# Instalar Kiali (opcional pero recomendado)
echo "🔍 Instalando Kiali..."
kubectl apply -f https://raw.githubusercontent.com/istio/istio/release-1.20/samples/addons/kiali.yaml

# Esperar a que Kiali esté listo
echo "⏳ Esperando a que Kiali esté listo..."
kubectl wait --for=condition=available --timeout=300s deployment/kiali -n istio-system

# Aplicar configuración de monitoreo
echo "⚙️ Aplicando configuración de monitoreo..."
if [ -f "k8s/monitoring/servicemonitor.yaml" ]; then
    kubectl apply -f k8s/monitoring/servicemonitor.yaml
    echo "✅ ServiceMonitors aplicados"
fi

# Verificar que todo esté corriendo
echo ""
echo "=== Estado de los servicios de monitoreo ==="
kubectl get pods -n istio-system | grep -E "prometheus|grafana|kiali"

echo ""
echo "=== 🎉 Instalación completada ==="
echo ""
echo "Para acceder a los dashboards, ejecuta estos comandos en OTRA terminal:"
echo ""
echo "# Prometheus (métricas)"
echo "kubectl port-forward -n istio-system svc/prometheus 9090:9090 --address 0.0.0.0"
echo "Accede en: http://192.168.100.10:9090"
echo ""
echo "# Grafana (visualización)"
echo "kubectl port-forward -n istio-system svc/grafana 3000:3000 --address 0.0.0.0"
echo "Accede en: http://192.168.100.10:3000"
echo ""
echo "# Kiali (service mesh)"
echo "kubectl port-forward -n istio-system svc/kiali 20001:20001 --address 0.0.0.0"
echo "Accede en: http://192.168.100.10:20001"
echo ""
echo "📌 Los dashboards de Istio ya están preconfigurados en Grafana"
echo ""
