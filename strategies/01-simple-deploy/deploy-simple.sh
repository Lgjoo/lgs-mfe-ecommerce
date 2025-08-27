#!/bin/bash

# Simple Deploy Script - Estratégia SEM Zero Downtime
# Este script implementa deploy direto com downtime

set -e

# Detectar diretório do projeto
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$(dirname "$SCRIPT_DIR")")"

APP_NAME=${1:-"lgs-mfe-container"}
NEW_IMAGE=${2:-"latest"}
CONTAINER_PORT=${3:-"4200"}

echo "🚀 Iniciando Deploy Direto para $APP_NAME"
echo "📦 Nova Imagem: $NEW_IMAGE"
echo "⚠️  ATENÇÃO: Esta estratégia terá DOWNTIME!"

# Função para verificar se container está rodando
check_container_running() {
    local container_name=$1
    if docker ps --format "table {{.Names}}" | grep -q "^${container_name}$"; then
        return 0
    else
        return 1
    fi
}

# Função para health check
health_check() {
    local container_name=$1
    local port=$2
    
    echo "🏥 Verificando saúde de $container_name..."
    
    # Aguardar container estar pronto
    sleep 10
    
    # Tentar health check
    if curl -f "http://localhost:$port/health" > /dev/null 2>&1; then
        echo "✅ $container_name está saudável"
        return 0
    else
        echo "❌ $container_name não está respondendo"
        return 1
    fi
}

# Backup da versão atual
if check_container_running "$APP_NAME"; then
    echo "💾 Fazendo backup da versão atual..."
    CURRENT_IMAGE=$(docker inspect --format='{{.Config.Image}}' "$APP_NAME")
    echo "📋 Versão atual: $CURRENT_IMAGE"
    
    # Tag da versão atual como backup
    docker tag "$CURRENT_IMAGE" "${APP_NAME}:backup-$(date +%Y%m%d-%H%M%S)"
else
    echo "ℹ️  Container $APP_NAME não está rodando"
fi

# Parar e remover container atual
echo "🛑 Parando container atual..."
docker stop "$APP_NAME" 2>/dev/null || true
docker rm "$APP_NAME" 2>/dev/null || true

# Build da nova imagem
echo "🔨 Construindo nova imagem..."
cd "$PROJECT_ROOT/$APP_NAME" || exit 1
docker build -t "$APP_NAME:$NEW_IMAGE" .
cd "$PROJECT_ROOT/strategies/01-simple-deploy"

# Deploy da nova versão
echo "🚀 Deployando nova versão..."
docker run -d \
    --name "$APP_NAME" \
    --network mfe-network \
    -p "$CONTAINER_PORT:4200" \
    "$APP_NAME:$NEW_IMAGE"

# Health check
if health_check "$APP_NAME" "$CONTAINER_PORT"; then
    echo "🎉 Deploy concluído com sucesso!"
    echo "🌐 Aplicação disponível em: http://localhost:$CONTAINER_PORT"
else
    echo "❌ Deploy falhou! Fazendo rollback..."
    
    # Rollback automático
    if docker images | grep -q "${APP_NAME}:backup"; then
        echo "🔄 Fazendo rollback para versão anterior..."
        docker stop "$APP_NAME" 2>/dev/null || true
        docker rm "$APP_NAME" 2>/dev/null || true
        
        # Encontrar backup mais recente
        BACKUP_IMAGE=$(docker images --format "table {{.Repository}}:{{.Tag}}" | grep "${APP_NAME}:backup" | head -1)
        
        if [ -n "$BACKUP_IMAGE" ]; then
            docker run -d \
                --name "$APP_NAME" \
                --network mfe-network \
                -p "$CONTAINER_PORT:4200" \
                "$BACKUP_IMAGE"
            
                    echo "✅ Rollback concluído"
    else
        echo "❌ Falha no rollback - backup não encontrado"
        exit 1
    fi
else
    echo "❌ Falha no rollback - sem backup disponível"
    exit 1
fi

echo ""
echo "⏸️  Pressione ENTER para fechar..."
read -r
fi
