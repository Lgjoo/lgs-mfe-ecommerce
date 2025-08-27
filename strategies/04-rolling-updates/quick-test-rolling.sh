#!/bin/bash

# Script de Teste Rápido para Rolling Updates
# Este script testa a funcionalidade básica sem Docker Swarm

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

echo "🔄 Teste Rápido - Rolling Updates"
echo "================================="
echo ""

# Verificar se Docker está rodando
if ! docker info > /dev/null 2>&1; then
    log_error "Docker não está rodando!"
    echo "⏸️  Pressione ENTER para fechar..."
    read -r
    exit 1
fi

# Verificar se rede existe
if ! docker network ls | grep -q "mfe-network"; then
    log_warning "Rede mfe-network não existe"
    log_info "Criando rede..."
    docker network create mfe-network
    log_success "Rede criada"
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

# Verificar Docker Swarm
echo ""
log_info "Verificando Docker Swarm..."

if docker info | grep -q "Swarm: active"; then
    log_success "Docker Swarm está ativo"
    
    # Verificar se stack está rodando
    if docker stack ls | grep -q "lgs-mfe"; then
        log_info "Stack lgs-mfe está rodando"
        echo ""
        log_info "Serviços ativos:"
        docker stack services lgs-mfe
    else
        log_warning "Stack lgs-mfe não está rodando"
        log_info "Para iniciar: docker stack deploy -c docker-stack-fixed.yml lgs-mfe"
    fi
    
else
    log_warning "Docker Swarm não está ativo"
    log_info "Para ativar: docker swarm init"
    echo ""
    log_info "Alternativa: Use o script de teste simulado"
    log_info "   ./test-rolling-updates.sh lgs-mfe-container"
fi

# Verificar Kubernetes (se disponível)
echo ""
log_info "Verificando Kubernetes..."

if command -v kubectl > /dev/null 2>&1; then
    log_success "kubectl encontrado"
    
    # Verificar se há cluster ativo
    if kubectl cluster-info > /dev/null 2>&1; then
        log_success "Cluster Kubernetes ativo"
        
        # Verificar deployments
        if kubectl get deployments | grep -q "lgs-mfe-container"; then
            log_info "Deployment lgs-mfe-container ativo"
            kubectl get deployments -l app=lgs-mfe-container
        else
            log_warning "Deployment lgs-mfe-container não encontrado"
            log_info "Para aplicar: kubectl apply -f k8s-deployment.yml"
        fi
        
    else
        log_warning "Cluster Kubernetes não está acessível"
    fi
    
else
    log_warning "kubectl não encontrado"
    log_info "Para instalar: https://kubernetes.io/docs/tasks/tools/"
fi

# Verificar arquivos de configuração
echo ""
log_info "Verificando arquivos de configuração..."

CONFIG_FILES=(
    "docker-stack.yml"
    "docker-stack-fixed.yml"
    "k8s-deployment.yml"
    "test-rolling-updates.sh"
)

for file in "${CONFIG_FILES[@]}"; do
    if [ -f "$file" ]; then
        log_success "$file encontrado"
    else
        log_error "$file não encontrado"
    fi
done

# Verificar sintaxe YAML
echo ""
log_info "Verificando sintaxe YAML..."

if command -v python3 > /dev/null 2>&1; then
    if python3 -c "import yaml; yaml.safe_load(open('docker-stack.yml'))" > /dev/null 2>&1; then
        log_success "docker-stack.yml - sintaxe válida"
    else
        log_error "docker-stack.yml - erro de sintaxe"
        log_info "Use docker-stack-fixed.yml como alternativa"
    fi
    
    if python3 -c "import yaml; yaml.safe_load(open('k8s-deployment.yml'))" > /dev/null 2>&1; then
        log_success "k8s-deployment.yml - sintaxe válida"
    else
        log_error "k8s-deployment.yml - erro de sintaxe"
    fi
    
else
    log_warning "python3 não encontrado - não é possível validar YAML"
fi

# Resumo final
echo ""
echo "📊 RESUMO DO TESTE RÁPIDO"
echo "=========================="

if [ ${#MISSING_IMAGES[@]} -eq 0 ] && docker info | grep -q "Swarm: active"; then
    log_success "✅ Ambiente Rolling Updates está pronto!"
    log_info "Execute: docker stack deploy -c docker-stack-fixed.yml lgs-mfe"
elif [ ${#MISSING_IMAGES[@]} -eq 0 ]; then
    log_warning "⚠️  Imagens OK, mas Docker Swarm inativo"
    log_info "Execute: docker swarm init"
    log_info "Ou use: ./test-rolling-updates.sh lgs-mfe-container"
else
    log_error "❌ Ambiente não está pronto"
    log_info "Corrija os problemas acima antes de continuar"
fi

echo ""
echo "⏸️  Pressione ENTER para fechar..."
read -r

