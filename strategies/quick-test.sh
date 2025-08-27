#!/bin/bash

# Script de Teste Rápido - Pode ser executado de qualquer diretório
# Este script detecta automaticamente o diretório do projeto e executa os testes

set -e

echo "🚀 Teste Rápido das Estratégias CI/CD"
echo "====================================="
echo ""

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

# Detectar diretório do projeto
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

echo "🔍 Diretório do script: $SCRIPT_DIR"
echo "🔍 Diretório raiz do projeto: $PROJECT_ROOT"
echo ""

# Verificar se estamos no diretório correto
if [ ! -d "$PROJECT_ROOT/lgs-mfe-container" ]; then
    log_error "Diretório lgs-mfe-container não encontrado em $PROJECT_ROOT"
    log_error "Execute este script do diretório raiz do projeto ou de strategies/"
    exit 1
fi

# Mudar para o diretório raiz do projeto
cd "$PROJECT_ROOT"
echo "📁 Mudando para diretório: $(pwd)"
echo ""

# Verificar Docker
log_info "Verificando Docker..."
if ! command -v docker &> /dev/null; then
    log_error "Docker não está instalado!"
    exit 1
fi

if ! docker version &> /dev/null; then
    log_error "Docker não está rodando!"
    exit 1
fi

log_success "Docker está funcionando"

# Criar rede se não existir
if ! docker network ls | grep -q "mfe-network"; then
    log_info "Criando rede mfe-network..."
    docker network create mfe-network
    log_success "Rede criada!"
else
    log_success "Rede mfe-network já existe!"
fi

echo ""

# Verificar imagens
log_info "Verificando imagens das aplicações..."

# Container
if ! docker images | grep -q "lgs-mfe-container"; then
    log_warning "Imagem lgs-mfe-container não encontrada. Fazendo build..."
    if [ -d "lgs-mfe-container" ]; then
        cd lgs-mfe-container
        if docker build -t lgs-mfe-container:latest .; then
            log_success "Build da imagem container concluído"
        else
            log_error "Falha no build da imagem container"
            exit 1
        fi
        cd ..
    else
        log_error "Diretório lgs-mfe-container não encontrado"
        exit 1
    fi
else
    log_success "Imagem lgs-mfe-container encontrada"
fi

# Catalog
if ! docker images | grep -q "lgs-mfe-catalog"; then
    log_warning "Imagem lgs-mfe-catalog não encontrada. Fazendo build..."
    if [ -d "lgs-mfe-catalog" ]; then
        cd "$PROJECT_ROOT/lgs-mfe-catalog"
        if docker build -t lgs-mfe-catalog:latest .; then
            log_success "Build da imagem catalog concluído"
        else
            log_error "Falha no build da imagem catalog"
        fi
        cd "$PROJECT_ROOT/strategies"
    else
        log_warning "Diretório lgs-mfe-catalog não encontrado"
    fi
else
    log_success "Imagem lgs-mfe-catalog encontrada"
fi

# Cart
if ! docker images | grep -q "lgs-mfe-cart"; then
    log_warning "Imagem lgs-mfe-cart não encontrada. Fazendo build..."
    if [ -d "lgs-mfe-cart" ]; then
        cd "$PROJECT_ROOT/lgs-mfe-cart"
        if docker build -t lgs-mfe-cart:latest .; then
            log_success "Build da imagem cart concluído"
        else
            log_error "Falha no build da imagem cart"
        fi
        cd "$PROJECT_ROOT/strategies"
    else
        log_warning "Diretório lgs-mfe-cart não encontrado"
    fi
else
    log_success "Imagem lgs-mfe-cart encontrada"
fi

echo ""

# Limpar containers conflitantes
log_info "Limpando containers conflitantes..."
docker stop lgs-mfe-container lgs-mfe-container-blue lgs-mfe-container-green lgs-mfe-container-canary lgs-mfe-container-main 2>/dev/null || true
docker rm lgs-mfe-container lgs-mfe-container-blue lgs-mfe-container-green lgs-mfe-container-canary lgs-mfe-container-main 2>/dev/null || true
log_success "Containers conflitantes removidos"

echo ""

# Corrigir permissões dos scripts
log_info "Corrigindo permissões dos scripts..."
find strategies/ -name "*.sh" -exec chmod +x {} \;
log_success "Permissões corrigidas"

echo ""

# Executar teste simples primeiro
log_info "🧪 Testando Estratégia 1: Simple Deploy"
echo "-------------------------------------------"

cd strategies/01-simple-deploy

if [ -f "deploy-simple.sh" ]; then
    log_info "Executando deploy simples..."
    if ./deploy-simple.sh lgs-mfe-container latest; then
        log_success "Simple Deploy executado com sucesso!"
        
        # Aguardar um pouco e verificar se está funcionando
        sleep 10
        
        if curl -f http://localhost:4200/health 2>/dev/null; then
            log_success "Health check passou!"
        else
            log_warning "Health check falhou, mas deploy foi executado"
        fi
        
        # Parar o container para não interferir nos outros testes
        docker stop lgs-mfe-container 2>/dev/null || true
        docker rm lgs-mfe-container 2>/dev/null || true
        
    else
        log_error "Simple Deploy falhou!"
    fi
else
    log_error "Script deploy-simple.sh não encontrado"
fi

cd "$PROJECT_ROOT"

echo ""

# Verificar status final
log_info "📊 Status final dos containers:"
if docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" | grep -q "lgs-mfe"; then
    docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" | grep "lgs-mfe"
else
    log_info "Nenhum container lgs-mfe ativo"
fi

echo ""

log_success "🎉 Teste rápido concluído!"
log_info "Para executar todos os testes:"
echo "   bash strategies/test-all-strategies.sh"
echo ""
log_info "Para executar correção automática:"
echo "   bash strategies/fix-common-issues.sh"
echo ""
log_info "Para diagnóstico detalhado:"
echo "   bash strategies/diagnose-issues.sh"

echo ""
log_info "⏸️  Pressione ENTER para fechar..."
read -r
