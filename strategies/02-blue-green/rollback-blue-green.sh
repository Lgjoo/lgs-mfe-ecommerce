#!/bin/bash

# Script de Rollback para Blue-Green Deployment
# Este script faz rollback para o ambiente anterior

set -e

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

echo "🔄 Rollback para Blue-Green Deployment"
echo "====================================="
echo ""

# Verificar argumentos
if [ $# -eq 0 ]; then
    echo "Uso: $0 <nome-da-aplicacao>"
    echo ""
    echo "Exemplo:"
    echo "  $0 lgs-mfe-container"
    echo ""
    echo "⏸️  Pressione ENTER para fechar..."
    read -r
    exit 1
fi

APP_NAME=$1

echo "📋 Aplicação: $APP_NAME"
echo ""

# Verificar qual ambiente está ativo
if docker ps --format "table {{.Names}}" | grep -q "${APP_NAME}-blue"; then
    ACTIVE_ENV="blue"
    INACTIVE_ENV="green"
    log_info "Ambiente BLUE está ativo"
elif docker ps --format "table {{.Names}}" | grep -q "${APP_NAME}-green"; then
    ACTIVE_ENV="green"
    INACTIVE_ENV="blue"
    log_info "Ambiente GREEN está ativo"
else
    log_error "Nenhum ambiente Blue-Green encontrado para $APP_NAME"
    echo ""
    log_info "Containers ativos:"
    docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" | grep "$APP_NAME" || echo "Nenhum container encontrado"
    echo ""
    echo "⏸️  Pressione ENTER para fechar..."
    read -r
    exit 1
fi

# Verificar se o ambiente inativo existe e está funcionando
if docker ps --format "table {{.Names}}" | grep -q "${APP_NAME}-${INACTIVE_ENV}"; then
    log_info "Ambiente ${INACTIVE_ENV^^} encontrado, verificando saúde..."
    
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
    
    # Health check do ambiente inativo
    if curl -f "http://localhost:$PORT/health" > /dev/null 2>&1; then
        log_success "Ambiente ${INACTIVE_ENV^^} está saudável"
        
        # Fazer rollback
        log_info "Executando rollback para ambiente ${INACTIVE_ENV^^}..."
        
        # Parar ambiente ativo
        docker stop "${APP_NAME}-${ACTIVE_ENV}"
        docker rm "${APP_NAME}-${ACTIVE_ENV}"
        log_success "Ambiente ${ACTIVE_ENV^^} parado"
        
        # Renomear ambiente inativo para ativo
        docker rename "${APP_NAME}-${INACTIVE_ENV}" "${APP_NAME}-${ACTIVE_ENV}"
        log_success "Ambiente ${INACTIVE_ENV^^} renomeado para ${ACTIVE_ENV^^}"
        
        # Verificar status final
        echo ""
        log_info "Status após rollback:"
        docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" | grep "$APP_NAME"
        
        log_success "Rollback concluído com sucesso!"
        log_info "Ambiente ${INACTIVE_ENV^^} agora está ativo na porta $PORT"
        
    else
        log_error "Ambiente ${INACTIVE_ENV^^} não está saudável"
        log_warning "Rollback não pode ser executado"
    fi
    
else
    log_error "Ambiente ${INACTIVE_ENV^^} não encontrado"
    log_warning "Rollback não pode ser executado - ambiente inativo não existe"
fi

echo ""
echo "⏸️  Pressione ENTER para fechar..."
read -r

