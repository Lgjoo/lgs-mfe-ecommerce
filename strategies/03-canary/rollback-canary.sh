#!/bin/bash

# Script de Rollback para Canary Deployment
# Este script faz rollback para a versão principal

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

echo "🔄 Rollback para Canary Deployment"
echo "================================="
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

# Verificar se há ambiente canary ativo
if docker ps --format "table {{.Names}}" | grep -q "${APP_NAME}-canary"; then
    log_info "Ambiente CANARY encontrado, executando rollback..."
    
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
    
    # Verificar se ambiente principal ainda existe
    if docker ps --format "table {{.Names}}" | grep -q "${APP_NAME}-main"; then
        log_info "Ambiente MAIN encontrado, verificando saúde..."
        
        # Health check do ambiente principal
        if curl -f "http://localhost:$PORT/health" > /dev/null 2>&1; then
            log_success "Ambiente MAIN está saudável"
            
            # Parar ambiente canary
            log_info "Parando ambiente CANARY..."
            docker stop "${APP_NAME}-canary"
            docker rm "${APP_NAME}-canary"
            log_success "Ambiente CANARY parado e removido"
            
            # Verificar status final
            echo ""
            log_info "Status após rollback:"
            docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" | grep "$APP_NAME"
            
            log_success "Rollback concluído com sucesso!"
            log_info "Ambiente MAIN está ativo na porta $PORT"
            
        else
            log_error "Ambiente MAIN não está saudável"
            log_warning "Rollback não pode ser executado - ambiente principal com problemas"
        fi
        
    else
        log_error "Ambiente MAIN não encontrado"
        log_warning "Rollback não pode ser executado - ambiente principal não existe"
        
        # Tentar restaurar a partir de backup
        log_info "Tentando restaurar a partir de backup..."
        
        if docker images | grep -q "${APP_NAME}:backup"; then
            log_info "Backup encontrado, restaurando..."
            
            # Parar ambiente canary
            docker stop "${APP_NAME}-canary"
            docker rm "${APP_NAME}-canary"
            
            # Restaurar a partir do backup
            docker run -d \
                --name "${APP_NAME}-main" \
                --network mfe-network \
                -p "$PORT:4200" \
                "${APP_NAME}:backup"
            
            log_success "Restauração a partir de backup concluída"
            
        else
            log_error "Nenhum backup disponível"
            log_warning "Rollback não pode ser executado"
        fi
    fi
    
else
    log_info "Nenhum ambiente CANARY ativo encontrado"
    log_info "Status atual dos containers:"
    docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" | grep "$APP_NAME" || echo "Nenhum container encontrado"
fi

echo ""
echo "⏸️  Pressione ENTER para fechar..."
read -r

