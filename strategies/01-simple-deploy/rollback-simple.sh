#!/bin/bash

# Script de Rollback para Simple Deploy
# Este script faz rollback para uma versão anterior

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

echo "🔄 Rollback para Simple Deploy"
echo "=============================="
echo ""

# Verificar argumentos
if [ $# -eq 0 ]; then
    echo "Uso: $0 <nome-da-aplicacao> [versao-backup]"
    echo ""
    echo "Exemplos:"
    echo "  $0 lgs-mfe-container"
    echo "  $0 lgs-mfe-container backup-20240115-143022"
    echo ""
    echo "⏸️  Pressione ENTER para fechar..."
    read -r
    exit 1
fi

APP_NAME=$1
BACKUP_VERSION=${2:-"backup"}

echo "📋 Aplicação: $APP_NAME"
echo "📦 Versão de backup: $BACKUP_VERSION"
echo ""

# Verificar se container está rodando
if docker ps --format "table {{.Names}}" | grep -q "^${APP_NAME}$"; then
    log_info "Container $APP_NAME está rodando"
    log_info "Parando container atual..."
    docker stop "$APP_NAME"
    docker rm "$APP_NAME"
    log_success "Container atual parado e removido"
else
    log_info "Container $APP_NAME não está rodando"
fi

# Verificar se imagem de backup existe
if docker images | grep -q "${APP_NAME}:${BACKUP_VERSION}"; then
    log_info "Imagem de backup encontrada: ${APP_NAME}:${BACKUP_VERSION}"
    
    # Fazer deploy da versão de backup
    log_info "Fazendo deploy da versão de backup..."
    
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
    
    docker run -d \
        --name "$APP_NAME" \
        --network mfe-network \
        -p "$PORT:4200" \
        "${APP_NAME}:${BACKUP_VERSION}"
    
    # Aguardar container estar pronto
    sleep 10
    
    # Verificar se está funcionando
    if curl -f "http://localhost:$PORT/health" > /dev/null 2>&1; then
        log_success "Rollback concluído com sucesso!"
        log_info "Aplicação disponível em: http://localhost:$PORT"
        
        # Mostrar status
        echo ""
        log_info "Status do container:"
        docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" | grep "$APP_NAME"
        
    else
        log_warning "Rollback executado, mas health check falhou"
        log_info "Verifique os logs: docker logs $APP_NAME"
    fi
    
else
    log_error "Imagem de backup não encontrada: ${APP_NAME}:${BACKUP_VERSION}"
    echo ""
    log_info "Imagens disponíveis para $APP_NAME:"
    docker images | grep "$APP_NAME" || echo "Nenhuma imagem encontrada"
    echo ""
    log_info "Para fazer rollback, especifique uma versão válida:"
    echo "  $0 $APP_NAME <versao-especifica>"
fi

echo ""
echo "⏸️  Pressione ENTER para fechar..."
read -r

