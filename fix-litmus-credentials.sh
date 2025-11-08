#!/bin/bash

echo "=== 🔐 Obteniendo credenciales de Litmus ==="

# Verificar que Litmus esté instalado
if ! kubectl get namespace litmus &> /dev/null; then
    echo "❌ Litmus no está instalado"
    exit 1
fi

echo ""
echo "📦 Verificando pods de Litmus..."
kubectl get pods -n litmus

echo ""
echo "🔍 Buscando el servicio frontend..."
kubectl get svc -n litmus

# Obtener el nombre del pod del frontend
FRONTEND_POD=$(kubectl get pods -n litmus -l component=litmusportal-frontend -o jsonpath='{.items[0].metadata.name}')

if [ -z "$FRONTEND_POD" ]; then
    echo "❌ No se encontró el pod del frontend"
    echo ""
    echo "Intentando con otro selector..."
    FRONTEND_POD=$(kubectl get pods -n litmus -o jsonpath='{.items[0].metadata.name}')
fi

echo ""
echo "📋 Credenciales de Litmus:"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "🌐 URL: http://192.168.100.10:9091"
echo ""
echo "👤 Usuario: admin"
echo "🔑 Contraseña: litmus"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Si el login falla, intentar resetear
echo "Si el login no funciona, ejecuta este comando para resetear:"
echo ""
echo "kubectl exec -it -n litmus \$FRONTEND_POD -- /bin/sh -c \"echo 'admin:litmus' > /etc/litmus/credentials\""
echo ""

# Verificar si hay un secret con credenciales
echo "🔍 Buscando secrets con credenciales..."
kubectl get secrets -n litmus

# Intentar obtener credenciales del secret
ADMIN_PASSWORD=$(kubectl get secret -n litmus litmus-portal-admin-secret -o jsonpath='{.data.JWT_SECRET}' 2>/dev/null | base64 -d)

if [ ! -z "$ADMIN_PASSWORD" ]; then
    echo ""
    echo "✅ Contraseña encontrada en secret:"
    echo "🔑 Contraseña: $ADMIN_PASSWORD"
else
    echo ""
    echo "⚠️  No se pudo obtener la contraseña del secret"
    echo ""
    echo "Prueba estas credenciales alternativas:"
    echo "  Usuario: admin    Contraseña: litmus"
    echo "  Usuario: admin    Contraseña: admin"
fi

echo ""
echo "💡 Si aún no funciona, reinstala Litmus con:"
echo "   kubectl delete namespace litmus"
echo "   ./setup-litmus-chaos.sh"
echo ""