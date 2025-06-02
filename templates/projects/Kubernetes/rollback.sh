#!/bin/bash

# Script de rollback para Kubernetes
set -e

NAMESPACE=${NAMESPACE:-default}
REVISION=${REVISION:-}

echo "🔄 Iniciando rollback en Kubernetes"
echo "📦 Namespace: $NAMESPACE"

if [ -n "$REVISION" ]; then
    echo "📋 Revision: $REVISION"
    kubectl rollout undo deployment/mi-app --to-revision=$REVISION -n $NAMESPACE
else
    echo "📋 Rollback a la revisión anterior"
    kubectl rollout undo deployment/mi-app -n $NAMESPACE
fi

# Esperar a que el rollback esté completo
echo "⏳ Esperando a que el rollback esté completo..."
kubectl rollout status deployment/mi-app -n $NAMESPACE --timeout=300s

# Verificar el estado
echo "✅ Verificando estado después del rollback..."
kubectl get pods -l app=mi-app -n $NAMESPACE

echo "🎉 Rollback completado exitosamente!"
