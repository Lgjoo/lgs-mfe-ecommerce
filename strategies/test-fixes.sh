#!/bin/bash

# Script para testar se as correções de caminhos funcionaram
# Este script testa cada estratégia individualmente para verificar os caminhos

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

echo "🧪 Testando Correções de Caminhos"
echo "=================================="
echo ""

# Detectar diretório do projeto
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

echo "🔍 Diretório do script: $SCRIPT_DIR"
echo "🔍 Diretório raiz do projeto: $PROJECT_ROOT"
echo ""

# Mudar para o diretório raiz do projeto
cd "$PROJECT_ROOT"
echo "📁 Mudando para diretório: $(pwd)"
echo ""

# Verificar se rede existe
if ! docker network ls | grep -q "mfe-network"; then
    log_info "Criando rede mfe-network..."
    docker network create mfe-network
    log_success "Rede criada"
else
    log_success "Rede mfe-network já existe"
fi

# Verificar se imagens existem
log_info "Verificando imagens disponíveis..."

IMAGES=("lgs-mfe-container" "lgs-mfe-catalog" "lgs-mfe-cart")
MISSING_IMAGES=()

for img in "${IMAGES[@]}"; do
    if docker images | grep -q "$img"; then
        log_success "Imagem $img encontrada"
    else
        log_warning "Imagem $img não encontrada"
        MISSING_IMAGES+=("$img")
    fi
done

if [ ${#MISSING_IMAGES[@]} -gt 0 ]; then
    echo ""
    log_info "Para criar as imagens faltantes, execute:"
    for img in "${MISSING_IMAGES[@]}"; do
        echo "   cd $img && docker build -t $img:latest ."
    done
    echo ""
fi

# Limpar containers conflitantes
log_info "Limpando containers conflitantes..."
docker stop lgs-mfe-container lgs-mfe-container-blue lgs-mfe-container-green lgs-mfe-container-canary lgs-mfe-container-main 2>/dev/null || true
docker rm lgs-mfe-container lgs-mfe-container-blue lgs-mfe-container-green lgs-mfe-container-canary lgs-mfe-container-main 2>/dev/null || true
log_success "Containers conflitantes removidos"

echo ""
echo "🧪 TESTANDO ESTRATÉGIA 1: Simple Deploy"
echo "========================================"

cd "$PROJECT_ROOT/strategies/01-simple-deploy"

if [ -f "deploy-simple.sh" ]; then
    log_info "Script encontrado, testando caminhos..."
    
    # Testar se o script consegue encontrar o diretório da aplicação
    if ./deploy-simple.sh lgs-mfe-container latest 2>&1 | grep -q "Construindo nova imagem"; then
        log_success "✅ Caminhos corrigidos! Script consegue acessar lgs-mfe-container"
    else
        log_error "❌ Caminhos ainda com problema"
    fi
    
    # Parar o container se foi criado
    docker stop lgs-mfe-container 2>/dev/null || true
    docker rm lgs-mfe-container 2>/dev/null || true
    
else
    log_error "Script deploy-simple.sh não encontrado"
fi

echo ""
echo "🧪 TESTANDO ESTRATÉGIA 2: Blue-Green"
echo "====================================="

cd "$PROJECT_ROOT/strategies/02-blue-green"

if [ -f "deploy-blue-green.sh" ]; then
    log_info "Script encontrado, testando caminhos..."
    
    # Testar se o script consegue encontrar o diretório da aplicação
    if ./deploy-blue-green.sh lgs-mfe-container latest 2>&1 | grep -q "Construindo nova imagem"; then
        log_success "✅ Caminhos corrigidos! Script consegue acessar lgs-mfe-container"
    else
        log_error "❌ Caminhos ainda com problema"
    fi
    
    # Parar containers se foram criados
    docker stop lgs-mfe-container-blue lgs-mfe-container-green 2>/dev/null || true
    docker rm lgs-mfe-container-blue lgs-mfe-container-green 2>/dev/null || true
    
else
    log_error "Script deploy-blue-green.sh não encontrado"
fi

echo ""
echo "🧪 TESTANDO ESTRATÉGIA 3: Canary"
echo "================================="

cd "$PROJECT_ROOT/strategies/03-canary"

if [ -f "deploy-canary.sh" ]; then
    log_info "Script encontrado, testando caminhos..."
    
    # Testar se o script consegue encontrar o diretório da aplicação
    if ./deploy-canary.sh lgs-mfe-container latest 2>&1 | grep -q "Construindo nova imagem"; then
        log_success "✅ Caminhos corrigidos! Script consegue acessar lgs-mfe-container"
    else
        log_error "❌ Caminhos ainda com problema"
    fi
    
    # Parar containers se foram criados
    docker stop lgs-mfe-container-canary lgs-mfe-container-main 2>/dev/null || true
    docker rm lgs-mfe-container-canary lgs-mfe-container-main 2>/dev/null || true
    
else
    log_error "Script deploy-canary.sh não encontrado"
fi

echo ""
echo "🧪 TESTANDO ESTRATÉGIA 4: Rolling Updates"
echo "=========================================="

cd "$PROJECT_ROOT/strategies/04-rolling-updates"

if [ -f "test-rolling-updates.sh" ]; then
    log_info "Script encontrado, testando caminhos..."
    
    # Testar se o script consegue encontrar o diretório da aplicação
    if ./test-rolling-updates.sh lgs-mfe-container latest 2>&1 | grep -q "Construindo nova imagem"; then
        log_success "✅ Caminhos corrigidos! Script consegue acessar lgs-mfe-container"
    else
        log_error "❌ Caminhos ainda com problema"
    fi
    
    # Parar containers se foram criados
    docker stop lgs-mfe-container lgs-mfe-container-new lgs-mfe-container-old 2>/dev/null || true
    docker rm lgs-mfe-container lgs-mfe-container-new lgs-mfe-container-old 2>/dev/null || true
    
else
    log_error "Script test-rolling-updates.sh não encontrado"
fi

echo ""
echo "📊 RESUMO DOS TESTES"
echo "===================="

log_info "Testes de caminhos concluídos!"
log_info "Se todos os testes passaram, os caminhos estão corrigidos."
log_info "Execute agora: bash strategies/test-all-strategies.sh"

echo ""
echo "⏸️  Pressione ENTER para fechar..."
read -r

