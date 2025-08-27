#!/bin/bash

# Script de Teste para Rolling Updates
# Este script testa a funcionalidade de Rolling Updates sem Docker Swarm

set -e

# Detectar diretório do projeto
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$(dirname "$SCRIPT_DIR")")"

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Função para log colorido
log_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

log_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

log_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

log_error() {
    echo -e "${RED}❌ $1${NC}"
}

echo "🔄 Teste de Rolling Updates"
echo "==========================="
echo ""

# Verificar argumentos
if [ $# -eq 0 ]; then
    echo "Uso: $0 <nome-da-aplicacao> [versao-nova]"
    echo ""
    echo "Exemplo:"
    echo "  $0 lgs-mfe-container"
    echo "  $0 lgs-mfe-container v1.2.0"
    echo ""
    echo "⏸️  Pressione ENTER para fechar..."
    read -r
    exit 1
fi

APP_NAME=$1
NEW_VERSION=${2:-"latest"}

echo "📋 Aplicação: $APP_NAME"
echo "📦 Nova Versão: $NEW_VERSION"
echo ""

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

# Determinar porta baseada no nome da aplicação
case $APP_NAME in
    "lgs-mfe-container")
        PORT=4200
        ;;
    "lgs-mfe-catalog")
        PORT=4201
        ;;
    "lgs-mfe-cart")
        PORT=4202
        ;;
    *)
        PORT=4200
        ;;
esac

echo "🔍 Verificando ambiente atual..."

# Verificar se aplicação está rodando
if check_container_running "$APP_NAME"; then
    log_info "Container $APP_NAME está rodando"
    
    # Verificar versão atual
    CURRENT_IMAGE=$(docker inspect --format='{{.Config.Image}}' "$APP_NAME")
    echo "📋 Versão atual: $CURRENT_IMAGE"
    
    # Fazer backup da versão atual
    log_info "💾 Fazendo backup da versão atual..."
    docker tag "$CURRENT_IMAGE" "${APP_NAME}:backup-$(date +%Y%m%d-%H%M%S)"
    log_success "Backup criado"
    
else
    log_warning "Container $APP_NAME não está rodando"
    log_info "Iniciando container inicial..."
    
    # Verificar se imagem existe
    if docker images | grep -q "$APP_NAME"; then
        docker run -d \
            --name "$APP_NAME" \
            --network mfe-network \
            -p "$PORT:4200" \
            "$APP_NAME:latest"
        
        if health_check "$APP_NAME" "$PORT"; then
            log_success "Container inicial iniciado com sucesso"
        else
            log_error "Falha ao iniciar container inicial"
            exit 1
        fi
    else
        log_error "Imagem $APP_NAME não encontrada"
        log_info "Execute primeiro: docker build -t $APP_NAME:latest ./$APP_NAME"
        echo ""
        echo "⏸️  Pressione ENTER para fechar..."
        read -r
        exit 1
    fi
fi

echo ""
log_info "🧪 Simulando Rolling Update..."

# Build da nova imagem
log_info "🔨 Construindo nova imagem..."
cd "$PROJECT_ROOT/$APP_NAME" || exit 1
docker build -t "$APP_NAME:$NEW_VERSION" .
cd "$PROJECT_ROOT/strategies/04-rolling-updates"

# Criar container temporário com nova versão
log_info "🚀 Criando container temporário com nova versão..."
docker run -d \
    --name "${APP_NAME}-new" \
    --network mfe-network \
    -p "$((PORT + 1000)):4200" \
    "$APP_NAME:$NEW_VERSION"

# Health check da nova versão
log_info "🏥 Verificando saúde da nova versão..."
if health_check "${APP_NAME}-new" "$((PORT + 1000))"; then
    log_success "Nova versão está saudável"
    
    # Simular transferência de tráfego
    log_info "🔄 Simulando transferência de tráfego..."
    
    # Parar versão antiga
    log_info "🛑 Parando versão antiga..."
    docker stop "$APP_NAME"
    
    # Renomear containers
    docker rename "$APP_NAME" "${APP_NAME}-old"
    docker rename "${APP_NAME}-new" "$APP_NAME"
    
    # Ajustar porta do novo container
    docker stop "$APP_NAME"
    docker rm "$APP_NAME"
    
    docker run -d \
        --name "$APP_NAME" \
        --network mfe-network \
        -p "$PORT:4200" \
        "$APP_NAME:$NEW_VERSION"
    
    # Verificar se está funcionando
    if health_check "$APP_NAME" "$PORT"; then
        log_success "Rolling Update concluído com sucesso!"
        log_info "Nova versão ativa na porta $PORT"
        
        # Limpar versão antiga
        log_info "🧹 Limpando versão antiga..."
        docker stop "${APP_NAME}-old" 2>/dev/null || true
        docker rm "${APP_NAME}-old" 2>/dev/null || true
        
        # Mostrar status final
        echo ""
        log_info "Status após Rolling Update:"
        docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" | grep "$APP_NAME"
        
    else
        log_error "Rolling Update falhou! Fazendo rollback..."
        
        # Rollback automático
        docker stop "$APP_NAME" 2>/dev/null || true
        docker rm "$APP_NAME" 2>/dev/null || true
        
        # Restaurar versão antiga
        docker rename "${APP_NAME}-old" "$APP_NAME"
        docker start "$APP_NAME"
        
        log_success "Rollback concluído - versão anterior restaurada"
    fi
    
else
    log_error "Nova versão falhou no health check"
    log_info "Rolling Update cancelado"
    
    # Limpar container temporário
    docker stop "${APP_NAME}-new" 2>/dev/null || true
    docker rm "${APP_NAME}-new" 2>/dev/null || true
fi

echo ""
echo "⏸️  Pressione ENTER para fechar..."
read -r
