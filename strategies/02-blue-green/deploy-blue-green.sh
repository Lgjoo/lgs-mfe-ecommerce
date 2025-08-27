#!/bin/bash

# Blue-Green Deployment Script - Estratégia COM Zero Downtime
# Este script implementa deploy Blue-Green para zero downtime

set -e

# Detectar diretório do projeto
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$(dirname "$SCRIPT_DIR")")"

APP_NAME=${1:-"lgs-mfe-container"}
NEW_IMAGE=${2:-"latest"}
BLUE_PORT=${3:-"4200"}
GREEN_PORT=${4:-"4201"}

echo "🔄 Iniciando Blue-Green Deployment para $APP_NAME"
echo "📦 Nova Imagem: $NEW_IMAGE"
echo "🔵 Blue Port: $BLUE_PORT"
echo "🟢 Green Port: $GREEN_PORT"

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
    
    echo "🏥 Verificando saúde de $container_name na porta $port..."
    
    # Aguardar container estar pronto
    sleep 15
    
    # Tentar health check
    if curl -f "http://localhost:$port/health" > /dev/null 2>&1; then
        echo "✅ $container_name está saudável na porta $port"
        return 0
    else
        echo "❌ $container_name não está respondendo na porta $port"
        return 1
    fi
}

# Função para determinar qual ambiente está ativo
get_active_environment() {
    if check_container_running "${APP_NAME}-blue"; then
        echo "blue"
    elif check_container_running "${APP_NAME}-green"; then
        echo "green"
    else
        echo "none"
    fi
}

# Verificar ambiente atual
ACTIVE_ENV=$(get_active_environment)
echo "🔍 Ambiente ativo atual: $ACTIVE_ENV"

# Determinar qual será o novo ambiente
if [ "$ACTIVE_ENV" = "blue" ]; then
    NEW_ENV="green"
    NEW_PORT=$GREEN_PORT
    OLD_ENV="blue"
    OLD_PORT=$BLUE_PORT
elif [ "$ACTIVE_ENV" = "green" ]; then
    NEW_ENV="blue"
    NEW_PORT=$BLUE_PORT
    OLD_ENV="green"
    OLD_PORT=$GREEN_PORT
else
    # Primeira execução, usar blue como padrão
    NEW_ENV="blue"
    NEW_PORT=$BLUE_PORT
    OLD_ENV="none"
    OLD_PORT=""
fi

echo "🆕 Novo ambiente: $NEW_ENV (porta $NEW_PORT)"
echo "🔄 Ambiente antigo: $OLD_ENV"

# Build da nova imagem
echo "🔨 Construindo nova imagem..."
cd "$PROJECT_ROOT/$APP_NAME" || exit 1
docker build -t "$APP_NAME:$NEW_IMAGE" .
cd "$PROJECT_ROOT/strategies/02-blue-green"

# Deploy no novo ambiente
echo "🚀 Deployando nova versão no ambiente $NEW_ENV..."
docker run -d \
    --name "${APP_NAME}-${NEW_ENV}" \
    --network mfe-network \
    -p "$NEW_PORT:4200" \
    "$APP_NAME:$NEW_IMAGE"

# Health check do novo ambiente
echo "🏥 Aguardando novo ambiente estar saudável..."
if health_check "${APP_NAME}-${NEW_ENV}" "$NEW_PORT"; then
    echo "✅ Novo ambiente $NEW_ENV está saudável!"
else
    echo "❌ Novo ambiente falhou no health check!"
    
    # Limpar ambiente falho
    docker stop "${APP_NAME}-${NEW_ENV}" 2>/dev/null || true
    docker rm "${APP_NAME}-${NEW_ENV}" 2>/dev/null || true
    
    echo "❌ Deploy falhou! Rollback necessário."
    exit 1
fi

# Se não é a primeira execução, fazer switch de tráfego
if [ "$OLD_ENV" != "none" ]; then
    echo "🔄 Fazendo switch de tráfego do $OLD_ENV para $NEW_ENV..."
    
    # Aqui você implementaria a lógica do load balancer
    # Por exemplo, atualizar nginx, haproxy, ou cloud load balancer
    echo "📝 Atualizando load balancer para direcionar tráfego para $NEW_ENV..."
    
    # Simular switch de tráfego (em produção, atualize seu load balancer)
    echo "🔄 Tráfego redirecionado para $NEW_ENV"
    
    # Aguardar um pouco para garantir que o switch foi feito
    sleep 10
    
    # Verificar se o novo ambiente ainda está saudável após o switch
    if health_check "${APP_NAME}-${NEW_ENV}" "$NEW_PORT"; then
        echo "✅ Switch de tráfego bem-sucedido!"
        
        # Parar ambiente antigo
        echo "🛑 Parando ambiente antigo $OLD_ENV..."
        docker stop "${APP_NAME}-${OLD_ENV}" 2>/dev/null || true
        docker rm "${APP_NAME}-${OLD_ENV}" 2>/dev/null || true
        
        echo "🎉 Blue-Green Deployment concluído com sucesso!"
        echo "🌐 Aplicação ativa em: http://localhost:$NEW_PORT"
        echo "🔄 Ambiente ativo: $NEW_ENV"
    else
        echo "❌ Novo ambiente falhou após switch de tráfego!"
        echo "🔄 Fazendo rollback automático..."
        
        # Rollback: voltar tráfego para ambiente antigo
        echo "📝 Revertendo load balancer para $OLD_ENV..."
        
        # Parar ambiente novo
        docker stop "${APP_NAME}-${NEW_ENV}" 2>/dev/null || true
        docker rm "${APP_NAME}-${NEW_ENV}" 2>/dev/null || true
        
        echo "❌ Rollback concluído. Ambiente $OLD_ENV ainda ativo."
        exit 1
    fi
else
    echo "🎉 Primeira execução concluída! Ambiente $NEW_ENV ativo."
    echo "🌐 Aplicação disponível em: http://localhost:$NEW_PORT"
fi

echo "✅ Blue-Green Deployment finalizado com sucesso!"

echo ""
echo "⏸️  Pressione ENTER para fechar..."
read -r
