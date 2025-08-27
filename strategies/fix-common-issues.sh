#!/bin/bash

# Script de Correção Automática de Problemas Comuns
# Este script corrige automaticamente os problemas mais frequentes

set -e

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

echo "🔧 Correção Automática de Problemas Comuns"
echo "=========================================="
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

# 1. Corrigir permissões dos scripts
echo "🔐 CORRIGINDO PERMISSÕES DOS SCRIPTS"
echo "====================================="

log_info "Corrigindo permissões de todos os scripts..."
find strategies/ -name "*.sh" -exec chmod +x {} \;
log_success "Permissões corrigidas para todos os scripts"

echo ""

# 2. Criar rede se não existir
echo "🌐 VERIFICANDO/CRIANDO REDE"
echo "============================"

if ! docker network ls | grep -q "mfe-network"; then
    log_info "Criando rede mfe-network..."
    docker network create mfe-network
    log_success "Rede mfe-network criada"
else
    log_success "Rede mfe-network já existe"
fi

echo ""

# 3. Fazer build das imagens
echo "📦 FAZENDO BUILD DAS IMAGENS"
echo "============================"

# Container
if [ -d "lgs-mfe-container" ]; then
    log_info "Fazendo build da imagem lgs-mfe-container..."
    cd lgs-mfe-container
    
    if docker build -t lgs-mfe-container:latest .; then
        log_success "Build da imagem container concluído"
    else
        log_error "Falha no build da imagem container"
        log_info "Verifique se há um Dockerfile válido no diretório"
    fi
    
    cd ..
else
    log_warning "Diretório lgs-mfe-container não encontrado"
fi

# Catalog
if [ -d "lgs-mfe-catalog" ]; then
    log_info "Fazendo build da imagem lgs-mfe-catalog..."
    cd lgs-mfe-catalog
    
    if docker build -t lgs-mfe-catalog:latest .; then
        log_success "Build da imagem catalog concluído"
    else
        log_error "Falha no build da imagem catalog"
    fi
    
    cd ..
else
    log_warning "Diretório lgs-mfe-catalog não encontrado"
fi

# Cart
if [ -d "lgs-mfe-cart" ]; then
    log_info "Fazendo build da imagem lgs-mfe-cart..."
    cd lgs-mfe-cart
    
    if docker build -t lgs-mfe-cart:latest .; then
        log_success "Build da imagem cart concluído"
    else
        log_error "Falha no build da imagem cart"
    fi
    
    cd ..
else
    log_warning "Diretório lgs-mfe-cart não encontrado"
fi

echo ""

# 4. Verificar e corrigir dependências
echo "🔍 VERIFICANDO DEPENDÊNCIAS"
echo "============================"

# curl
if ! command -v curl &> /dev/null; then
    log_warning "curl não encontrado"
    log_info "Instale curl para health checks funcionarem:"
    log_info "  Ubuntu/Debian: sudo apt-get install curl"
    log_info "  CentOS/RHEL: sudo yum install curl"
    log_info "  Windows: Baixe do site oficial ou use Git Bash"
else
    log_success "curl está disponível"
fi

# bc
if ! command -v bc &> /dev/null; then
    log_warning "bc não encontrado"
    log_info "Instale bc para cálculos matemáticos:"
    log_info "  Ubuntu/Debian: sudo apt-get install bc"
    log_info "  CentOS/RHEL: sudo yum install bc"
    log_info "  Windows: Use Git Bash ou WSL"
else
    log_success "bc está disponível"
fi

echo ""

# 5. Limpar containers conflitantes
echo "🧹 LIMPANDO CONTAINERS CONFLITANTES"
echo "==================================="

log_info "Parando containers conflitantes..."
docker stop lgs-mfe-container lgs-mfe-container-blue lgs-mfe-container-green lgs-mfe-container-canary lgs-mfe-container-main 2>/dev/null || true

log_info "Removendo containers conflitantes..."
docker rm lgs-mfe-container lgs-mfe-container-blue lgs-mfe-container-green lgs-mfe-container-canary lgs-mfe-container-main 2>/dev/null || true

log_success "Containers conflitantes removidos"

echo ""

# 6. Verificar Docker Swarm
echo "🐝 VERIFICANDO DOCKER SWARM"
echo "============================"

if docker info | grep -q "Swarm: active"; then
    log_success "Docker Swarm está ativo"
else
    log_warning "Docker Swarm não está ativo"
    log_info "Para ativar Docker Swarm, execute:"
    log_info "  docker swarm init"
    log_info ""
    log_info "Isso é necessário para a estratégia Rolling Updates funcionar"
fi

echo ""

# 7. Verificar sintaxe dos scripts
echo "📝 VERIFICANDO SINTAXE DOS SCRIPTS"
echo "==================================="

log_info "Verificando sintaxe de todos os scripts..."

# Simple Deploy
if [ -f "strategies/01-simple-deploy/deploy-simple.sh" ]; then
    if bash -n strategies/01-simple-deploy/deploy-simple.sh; then
        log_success "deploy-simple.sh: sintaxe OK"
    else
        log_error "deploy-simple.sh: erro de sintaxe"
    fi
fi

# Blue-Green
if [ -f "strategies/02-blue-green/deploy-blue-green.sh" ]; then
    if bash -n strategies/02-blue-green/deploy-blue-green.sh; then
        log_success "deploy-blue-green.sh: sintaxe OK"
    else
        log_error "deploy-blue-green.sh: erro de sintaxe"
    fi
fi

if [ -f "strategies/02-blue-green/status-blue-green.sh" ]; then
    if bash -n strategies/02-blue-green/status-blue-green.sh; then
        log_success "status-blue-green.sh: sintaxe OK"
    else
        log_error "status-blue-green.sh: erro de sintaxe"
    fi
fi

# Canary
if [ -f "strategies/03-canary/deploy-canary.sh" ]; then
    if bash -n strategies/03-canary/deploy-canary.sh; then
        log_success "deploy-canary.sh: sintaxe OK"
    else
        log_error "deploy-canary.sh: erro de sintaxe"
    fi
fi

echo ""

# 8. Verificar arquivos de configuração
echo "⚙️  VERIFICANDO ARQUIVOS DE CONFIGURAÇÃO"
echo "========================================"

# Docker Compose
if [ -f "strategies/01-simple-deploy/docker-compose.yml" ]; then
    if docker-compose -f strategies/01-simple-deploy/docker-compose.yml config >/dev/null 2>&1; then
        log_success "docker-compose.yml: configuração válida"
    else
        log_error "docker-compose.yml: configuração inválida"
    fi
fi

# Docker Stack
if [ -f "strategies/04-rolling-updates/docker-stack.yml" ]; then
    log_success "docker-stack.yml encontrado"
fi

# Kubernetes
if [ -f "strategies/04-rolling-updates/k8s-deployment.yml" ]; then
    log_success "k8s-deployment.yml encontrado"
fi

echo ""

# 9. Resumo das correções
echo "📋 RESUMO DAS CORREÇÕES APLICADAS"
echo "=================================="

log_success "✅ Permissões dos scripts corrigidas"
log_success "✅ Rede Docker verificada/criada"
log_success "✅ Build das imagens executado"
log_success "✅ Containers conflitantes removidos"
log_success "✅ Sintaxe dos scripts verificada"

echo ""
log_info "🎯 Agora você pode executar os testes novamente:"
echo ""
echo "   # Teste completo corrigido:"
echo "   bash strategies/test-all-strategies.sh"
echo ""
echo "   # Ou teste individual:"
echo "   bash strategies/01-simple-deploy/deploy-simple.sh lgs-mfe-container latest"
echo "   bash strategies/02-blue-green/deploy-blue-green.sh lgs-mfe-container latest"
echo "   bash strategies/03-canary/deploy-canary.sh lgs-mfe-container latest"
echo ""

log_info "🔍 Se ainda houver problemas, execute o diagnóstico:"
echo "   bash strategies/diagnose-issues.sh"
echo ""

log_info "🎉 Correções aplicadas com sucesso!"

echo ""
log_info "⏸️  Pressione ENTER para fechar..."
read -r
