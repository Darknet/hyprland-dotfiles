#!/bin/bash

# Script de despliegue para Kubernetes
set -e

NAMESPACE=${NAMESPACE:-default}
IMAGE_TAG=${IMAGE_TAG:-latest}
ENVIRONMENT=${ENVIRONMENT:-development}

echo "🚀 Iniciando despliegue en Kubernetes"
echo "📦 Namespace: $NAMESPACE"
echo "🏷️  Image Tag: $IMAGE_TAG"
echo "🌍 Environment: $ENVIRONMENT"

# Verificar que kubectl está disponible
if ! command -v kubectl &> /dev/null; then
    echo "❌ kubectl no está instalado"
    exit 1
fi

# Verificar conexión al cluster
if ! kubectl cluster-info &> /dev/null; then
    echo "❌ No se puede conectar al cluster de Kubernetes"
    exit 1
fi

# Crear namespace si no existe
kubectl create namespace $NAMESPACE --dry-run=client -o yaml | kubectl apply -f -

# Aplicar RBAC
echo "🔐 Aplicando configuración RBAC..."
kubectl apply -f rbac.yaml -n $NAMESPACE

# Aplicar ConfigMaps
echo "⚙️  Aplicando ConfigMaps..."
kubectl apply -f configmap.yaml -n $NAMESPACE

# Aplicar Secrets
echo "🔒 Aplicando Secrets..."
kubectl apply -f secret.yaml -n $NAMESPACE

# Aplicar NetworkPolicy
echo "🌐 Aplicando Network Policies..."
kubectl apply -f networkpolicy.yaml -n $NAMESPACE

# Actualizar imagen en deployment
echo "🔄 Actualizando imagen del deployment..."
sed "s|mi-registro/mi-app:latest|mi-registro/mi-app:$IMAGE_TAG|g" deployment.yaml | kubectl apply -f - -n $NAMESPACE

# Aplicar Service
echo "🔗 Aplicando Services..."
kubectl apply -f service.yaml -n $NAMESPACE

# Aplicar Ingress
echo "🌍 Aplicando Ingress..."
kubectl apply -f ingress.yaml -n $NAMESPACE

# Aplicar HPA
echo "📈 Aplicando HorizontalPodAutoscaler..."
kubectl apply -f hpa.yaml -n $NAMESPACE

# Aplicar PDB
echo "🛡️  Aplicando PodDisruptionBudget..."
kubectl apply -f pdb.yaml -n $NAMESPACE

# Esperar a que el deployment esté listo
echo "⏳ Esperando a que el deployment esté listo..."
kubectl rollout status deployment/mi-app -n $NAMESPACE --timeout=300s

# Verificar el estado
echo "✅ Verificando estado del despliegue..."
kubectl get pods -l app=mi-app -n $NAMESPACE
kubectl get services -l app=mi-app -n $NAMESPACE
kubectl get ingress -n $NAMESPACE

echo "🎉 Despliegue completado exitosamente!"
