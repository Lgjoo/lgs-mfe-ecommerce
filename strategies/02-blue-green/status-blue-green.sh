#!/bin/bash

# Status Blue-Green Script
# Este script verifica o status dos ambientes Blue e Green

APP_NAME=${1:-"lgs-mfe-container"}

echo "🔍 Verificando Status dos Ambientes Blue-Green para $APP_NAME"
echo "=================================================="

# Função para verificar se container está rodando
check_container_running() {
    local container_name=$1
    if docker ps --format "table {{.Names}}" | grep -q "^${container_name}$"; then
        return 0
    else
        return 1
    fi
}

# Função para obter informações do container
get_container_info() {
    local container_name=$1
    if check_container_running "$container_name"; then
        local image=$(docker inspect --format='{{.Config.Image}}' "$container_name" 2>/dev/null || echo "N/A")
        local status=$(docker inspect --format='{{.State.Status}}' "$container_name" 2>/dev/null || echo "N/A")
        local uptime=$(docker inspect --format='{{.State.StartedAt}}' "$container_name" 2>/dev/null || echo "N/A")
        local port=$(docker port "$container_name" 2>/dev/null | grep "4200/tcp" | cut -d: -f2 || echo "N/A")
        
        echo "✅ Status: Ativo"
        echo "   📦 Imagem: $image"
        echo "   🔄 Estado: $status"
        echo "   ⏰ Iniciado: $uptime"
        echo "   🌐 Porta: $port"
        return 0
    else
        echo "❌ Status: Inativo"
        return 1
    fi
}

# Verificar ambiente Blue
echo "🔵 AMBIENTE BLUE:"
echo "----------------"
BLUE_ACTIVE=false
if get_container_info "${APP_NAME}-blue"; then
    BLUE_ACTIVE=true
fi

echo ""

# Verificar ambiente Green
echo "🟢 AMBIENTE GREEN:"
echo "-----------------"
GREEN_ACTIVE=false
if get_container_info "${APP_NAME}-green"; then
    GREEN_ACTIVE=true
fi

echo ""

# Determinar ambiente ativo
echo "🎯 RESUMO:"
echo "---------"
if [ "$BLUE_ACTIVE" = true ] && [ "$GREEN_ACTIVE" = true ]; then
    echo "⚠️  AMBOS os ambientes estão ativos!"
    echo "   🔵 Blue: ${APP_NAME}-blue"
    echo "   🟢 Green: ${APP_NAME}-green"
    echo "   💡 Recomendação: Verificar qual está recebendo tráfego"
elif [ "$BLUE_ACTIVE" = true ]; then
    echo "🔵 AMBIENTE ATIVO: Blue"
    echo "   ✅ ${APP_NAME}-blue está rodando"
    echo "   🟢 ${APP_NAME}-green está inativo"
elif [ "$GREEN_ACTIVE" = true ]; then
    echo "🟢 AMBIENTE ATIVO: Green"
    echo "   ✅ ${APP_NAME}-green está rodando"
    echo "   🔵 ${APP_NAME}-blue está inativo"
else
    echo "❌ NENHUM ambiente está ativo!"
    echo "   💡 Recomendação: Executar deploy inicial"
fi

echo ""

# Verificar rede
echo "🌐 VERIFICAÇÃO DE REDE:"
echo "----------------------"
if docker network ls | grep -q "mfe-network"; then
    echo "✅ Rede mfe-network existe"
    
    # Verificar containers na rede
    echo "📋 Containers na rede mfe-network:"
    docker network inspect mfe-network --format='{{range .Containers}}{{.Name}} ({{.IPv4Address}}){{"\n"}}{{end}}' 2>/dev/null || echo "   Nenhum container conectado"
else
    echo "❌ Rede mfe-network não existe"
    echo "   💡 Recomendação: Criar rede com 'docker network create mfe-network'"
fi

echo ""

# Verificar imagens disponíveis
echo "📦 IMAGENS DISPONÍVEIS:"
echo "----------------------"
if docker images | grep -q "$APP_NAME"; then
    docker images "$APP_NAME" --format "table {{.Repository}}\t{{.Tag}}\t{{.Size}}\t{{.CreatedAt}}"
else
    echo "❌ Nenhuma imagem encontrada para $APP_NAME"
    echo "   💡 Recomendação: Fazer build da aplicação primeiro"
fi

echo ""
echo "🔍 Verificação de status concluída!"

echo ""
echo "⏸️  Pressione ENTER para fechar..."
read -r
