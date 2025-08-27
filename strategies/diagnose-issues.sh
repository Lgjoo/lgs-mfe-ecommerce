#!/bin/bash

# Script de Diagnóstico para Identificar Problemas nas Estratégias
# Este script verifica cada estratégia individualmente e identifica problemas específicos

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

echo "🔍 Diagnóstico de Problemas nas Estratégias CI/CD"
echo "================================================"
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

# Verificar ambiente básico
echo "🔧 VERIFICAÇÃO DO AMBIENTE BÁSICO"
echo "================================="

# Docker
log_info "Verificando Docker..."
if command -v docker &> /dev/null; then
    if docker version &> /dev/null; then
        log_success "Docker está rodando"
        docker --version
    else
        log_error "Docker não está rodando"
        exit 1
    fi
else
    log_error "Docker não está instalado"
    exit 1
fi

# Docker Compose
log_info "Verificando Docker Compose..."
if command -v docker-compose &> /dev/null; then
    log_success "Docker Compose disponível"
    docker-compose --version
else
    log_warning "Docker Compose não encontrado"
fi

# curl
log_info "Verificando curl..."
if command -v curl &> /dev/null; then
    log_success "curl disponível"
else
    log_warning "curl não encontrado - health checks podem falhar"
fi

# bc
log_info "Verificando bc..."
if command -v bc &> /dev/null; then
    log_success "bc disponível"
else
    log_warning "bc não encontrado - cálculos podem falhar"
fi

echo ""

# Verificar rede
echo "🌐 VERIFICAÇÃO DE REDE"
echo "====================="

if docker network ls | grep -q "mfe-network"; then
    log_success "Rede mfe-network existe"
else
    log_warning "Rede mfe-network não existe"
    log_info "Criando rede..."
    docker network create mfe-network
    log_success "Rede criada"
fi

echo ""

# Verificar imagens
echo "📦 VERIFICAÇÃO DE IMAGENS"
echo "========================="

log_info "Verificando imagens das aplicações..."

# Container
if docker images | grep -q "lgs-mfe-container"; then
    log_success "Imagem lgs-mfe-container encontrada"
    docker images | grep "lgs-mfe-container"
else
    log_warning "Imagem lgs-mfe-container não encontrada"
    log_info "Tentando fazer build..."
    if [ -d "lgs-mfe-container" ]; then
        cd lgs-mfe-container
        if docker build -t lgs-mfe-container:latest .; then
            log_success "Build da imagem container concluído"
        else
            log_error "Falha no build da imagem container"
        fi
        cd ..
    else
        log_error "Diretório lgs-mfe-container não encontrado"
    fi
fi

# Catalog
if docker images | grep -q "lgs-mfe-catalog"; then
    log_success "Imagem lgs-mfe-catalog encontrada"
    docker images | grep "lgs-mfe-catalog"
else
    log_warning "Imagem lgs-mfe-catalog não encontrada"
fi

# Cart
if docker images | grep -q "lgs-mfe-cart"; then
    log_success "Imagem lgs-mfe-cart encontrada"
    docker images | grep "lgs-mfe-cart"
else
    log_warning "Imagem lgs-mfe-cart não encontrada"
fi

echo ""

# Verificar cada estratégia individualmente
echo "🧪 VERIFICAÇÃO INDIVIDUAL DAS ESTRATÉGIAS"
echo "========================================="

# 1. Simple Deploy
echo "🔴 ESTRATÉGIA 1: Simple Deploy"
echo "-------------------------------"

cd strategies/01-simple-deploy

# Verificar se script existe
if [ -f "deploy-simple.sh" ]; then
    log_success "Script deploy-simple.sh encontrado"
    
    # Verificar permissões
    if [ -x "deploy-simple.sh" ]; then
        log_success "Script é executável"
    else
        log_warning "Script não é executável, corrigindo..."
        chmod +x deploy-simple.sh
        log_success "Permissões corrigidas"
    fi
    
    # Verificar sintaxe
    if bash -n deploy-simple.sh; then
        log_success "Sintaxe do script está correta"
    else
        log_error "Erro de sintaxe no script"
    fi
    
    # Verificar dependências
    log_info "Verificando dependências do script..."
    if grep -q "docker" deploy-simple.sh; then
        log_success "Script usa Docker"
    fi
    
    if grep -q "curl" deploy-simple.sh; then
        if command -v curl &> /dev/null; then
            log_success "Script usa curl e está disponível"
        else
            log_error "Script usa curl mas não está disponível"
        fi
    fi
    
else
    log_error "Script deploy-simple.sh não encontrado"
fi

cd ../..

echo ""

# 2. Blue-Green
echo "🔵 ESTRATÉGIA 2: Blue-Green"
echo "-----------------------------"

cd "$PROJECT_ROOT/strategies/02-blue-green"

# Verificar scripts
for script in "deploy-blue-green.sh" "status-blue-green.sh"; do
    if [ -f "$script" ]; then
        log_success "Script $script encontrado"
        
        # Verificar permissões
        if [ -x "$script" ]; then
            log_success "Script $script é executável"
        else
            log_warning "Script $script não é executável, corrigindo..."
            chmod +x "$script"
            log_success "Permissões corrigidas"
        fi
        
        # Verificar sintaxe
        if bash -n "$script"; then
            log_success "Sintaxe do script $script está correta"
        else
            log_error "Erro de sintaxe no script $script"
        fi
    else
        log_error "Script $script não encontrado"
    fi
done

cd ../..

echo ""

# 3. Canary
echo "🐦 ESTRATÉGIA 3: Canary"
echo "------------------------"

cd "$PROJECT_ROOT/strategies/03-canary"

if [ -f "deploy-canary.sh" ]; then
    log_success "Script deploy-canary.sh encontrado"
    
    # Verificar permissões
    if [ -x "deploy-canary.sh" ]; then
        log_success "Script é executável"
    else
        log_warning "Script não é executável, corrigindo..."
        chmod +x deploy-canary.sh
        log_success "Permissões corrigidas"
    fi
    
    # Verificar sintaxe
    if bash -n deploy-canary.sh; then
        log_success "Sintaxe do script está correta"
    else
        log_error "Erro de sintaxe no script"
    fi
    
    # Verificar dependências específicas
    if grep -q "bc" deploy-canary.sh; then
        if command -v bc &> /dev/null; then
            log_success "Script usa bc e está disponível"
        else
            log_error "Script usa bc mas não está disponível"
        fi
    fi
    
else
    log_error "Script deploy-canary.sh não encontrado"
fi

cd ../..

echo ""

# 4. Rolling Updates
echo "🔄 ESTRATÉGIA 4: Rolling Updates"
echo "--------------------------------"

cd "$PROJECT_ROOT/strategies/04-rolling-updates"

# Verificar arquivos de configuração
if [ -f "docker-stack.yml" ]; then
    log_success "docker-stack.yml encontrado"
    
    # Verificar sintaxe YAML
    if command -v python3 &> /dev/null; then
        if python3 -c "import yaml; yaml.safe_load(open('docker-stack.yml'))" 2>/dev/null; then
            log_success "Sintaxe YAML válida"
        else
            log_error "Erro na sintaxe YAML"
        fi
    else
        log_warning "Python3 não disponível para validar YAML"
    fi
else
    log_error "docker-stack.yml não encontrado"
fi

if [ -f "k8s-deployment.yml" ]; then
    log_success "k8s-deployment.yml encontrado"
else
    log_error "k8s-deployment.yml não encontrado"
fi

# Verificar Docker Swarm
log_info "Verificando Docker Swarm..."
if docker info | grep -q "Swarm: active"; then
    log_success "Docker Swarm está ativo"
else
    log_warning "Docker Swarm não está ativo"
    log_info "Para ativar: docker swarm init"
fi

cd ../..

echo ""

# Verificar containers ativos
echo "🔍 STATUS ATUAL DOS CONTAINERS"
echo "=============================="

log_info "Containers ativos:"
if docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" | grep -q "lgs-mfe"; then
    docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" | grep "lgs-mfe"
else
    log_warning "Nenhum container lgs-mfe ativo"
fi

echo ""

# Verificar portas em uso
echo "🌐 VERIFICAÇÃO DE PORTAS"
echo "========================"

log_info "Verificando portas em uso..."
for port in 4200 4201 4202; do
    if netstat -tuln 2>/dev/null | grep -q ":$port "; then
        log_warning "Porta $port está em uso"
        netstat -tuln | grep ":$port "
    else
        log_success "Porta $port está livre"
    fi
done

echo ""

# Resumo dos problemas encontrados
echo "📋 RESUMO DOS PROBLEMAS IDENTIFICADOS"
echo "====================================="

echo "Para resolver os problemas, execute:"
echo ""
echo "1. Corrigir permissões:"
echo "   chmod +x strategies/*/*.sh"
echo ""
echo "2. Fazer build das imagens:"
echo "   cd lgs-mfe-container && docker build -t lgs-mfe-container:latest ."
echo "   cd ../lgs-mfe-catalog && docker build -t lgs-mfe-catalog:latest ."
echo "   cd ../lgs-mfe-cart && docker build -t lgs-mfe-cart:latest ."
echo ""
echo "3. Ativar Docker Swarm (se necessário):"
echo "   docker swarm init"
echo ""
echo "4. Verificar se todas as dependências estão instaladas:"
echo "   - Docker"
echo "   - Docker Compose"
echo "   - curl"
echo "   - bc"
echo ""

log_info "Diagnóstico concluído!"
log_info "Execute os comandos acima para resolver os problemas identificados"

echo ""
log_info "⏸️  Pressione ENTER para fechar..."
read -r
