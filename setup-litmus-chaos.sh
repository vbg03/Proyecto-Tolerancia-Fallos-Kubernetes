#!/bin/bash

echo "=== Instalando LitmusChaos ==="

# Eliminar instalación anterior si existe
echo "🧹 Limpiando instalación anterior..."
helm uninstall chaos -n litmus 2>/dev/null || true
kubectl delete namespace litmus 2>/dev/null || true
sleep 5

# Crear namespace para Litmus
kubectl create namespace litmus

# Instalar Litmus usando Helm
helm repo add litmuschaos https://litmuschaos.github.io/litmus-helm/
helm repo update

echo "📦 Instalando Litmus con contraseña personalizada..."
helm install chaos litmuschaos/litmus \
  --namespace=litmus \
  --set portal.frontend.service.type=ClusterIP \
  --set portal.server.authServer.env.ADMIN_PASSWORD=admin123

# Esperar a que esté listo
echo "⏳ Esperando a que Litmus esté listo..."
kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=litmus --namespace=litmus --timeout=300s

echo ""
echo "✅ Litmus instalado!"
echo ""
echo "Para acceder a Litmus UI:"
echo "kubectl port-forward -n litmus svc/chaos-litmus-frontend-service 9091:9091 --address 0.0.0.0"
echo ""
echo "Luego accede en: http://192.168.100.10:9091"
echo "Usuario: admin"
echo "Contraseña: litmus"
echo ""

# Instalar experimentos de caos comunes
echo "📦 Instalando experimentos de caos..."
kubectl apply -f https://hub.litmuschaos.io/api/chaos/master?file=charts/generic/experiments.yaml -n default

echo ""
echo "🧪 Experimentos disponibles:"
kubectl get chaosexperiments -n default

echo ""
echo "=== 🎉 Instalación completada ==="