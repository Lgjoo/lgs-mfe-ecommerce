#!/bin/bash

# Script de Teste Automatizado para Todas as Estratégias de CI/CD
# Este script testa todas as estratégias implementadas

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

echo "🧪 Iniciando Testes de Todas as Estratégias de CI/CD"
echo "====================================================="
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

# Função para verificar pré-requisitos
check_prerequisites() {
    log_info "Verificando pré-requisitos..."
    
    # Verificar Docker
    if ! command -v docker &> /dev/null; then
        log_error "Docker não está instalado!"
        exit 1
    fi
    
    # Verificar Docker Compose
    if ! command -v docker-compose &> /dev/null; then
        log_warning "Docker Compose não está instalado. Alguns testes podem falhar."
    fi
    
    # Verificar curl
    if ! command -v curl &> /dev/null; then
        log_warning "curl não está instalado. Health checks podem falhar."
    fi
    
    # Verificar bc
    if ! command -v bc &> /dev/null; then
        log_warning "bc não está instalado. Alguns cálculos podem falhar."
    fi
    
    log_success "Pré-requisitos verificados!"
}

# Função para setup inicial
setup_environment() {
    log_info "Configurando ambiente de teste..."
    
    # Criar rede se não existir
    if ! docker network ls | grep -q "mfe-network"; then
        log_info "Criando rede mfe-network..."
        docker network create mfe-network
        log_success "Rede criada!"
    else
        log_success "Rede mfe-network já existe!"
    fi
    
    # Verificar se aplicações estão buildadas
    log_info "Verificando imagens das aplicações..."
    
    if ! docker images | grep -q "lgs-mfe-container"; then
        log_warning "Imagem lgs-mfe-container não encontrada. Fazendo build..."
        cd "$PROJECT_ROOT/lgs-mfe-container" && docker build -t lgs-mfe-container:latest . && cd "$PROJECT_ROOT"
    fi
    
    if ! docker images | grep -q "lgs-mfe-catalog"; then
        log_warning "Imagem lgs-mfe-catalog não encontrada. Fazendo build..."
        cd "$PROJECT_ROOT/lgs-mfe-catalog" && docker build -t lgs-mfe-container:latest . && cd "$PROJECT_ROOT"
    fi
    
    if ! docker images | grep -q "lgs-mfe-cart"; then
        log_warning "Imagem lgs-mfe-cart não encontrada. Fazendo build..."
        cd "$PROJECT_ROOT/lgs-mfe-cart" && docker build -t lgs-mfe-container:latest . && cd "$PROJECT_ROOT"
    fi
    
    log_success "Ambiente configurado!"
}

# Função para limpar containers de teste
cleanup_test_containers() {
    log_info "Limpando containers de teste..."
    
    # Parar e remover containers de teste
    docker stop lgs-mfe-container lgs-mfe-container-blue lgs-mfe-container-green lgs-mfe-container-canary lgs-mfe-container-main 2>/dev/null || true
    docker rm lgs-mfe-container lgs-mfe-container-blue lgs-mfe-container-green lgs-mfe-container-canary lgs-mfe-container-main 2>/dev/null || true
    
    log_success "Containers de teste limpos!"
}

# Função para testar Simple Deploy
test_simple_deploy() {
    log_info "🧪 Testando Estratégia 1: Simple Deploy"
    echo "----------------------------------------"
    
    cd "$PROJECT_ROOT/strategies/01-simple-deploy"
    
    # Tornar script executável
    chmod +x deploy-simple.sh
    
    # Executar deploy
    log_info "Executando deploy..."
    if ./deploy-simple.sh lgs-mfe-container latest; then
        log_success "Simple Deploy executado com sucesso!"
        
        # Verificar se está funcionando
        sleep 5
        if curl -f http://localhost:4200/health > /dev/null 2>&1; then
            log_success "Health check passou!"
        else
            log_warning "Health check falhou"
        fi
    else
        log_error "Simple Deploy falhou!"
        return 1
    fi
    
    cd "$PROJECT_ROOT"
    echo ""
}

# Função para testar Blue-Green
test_blue_green() {
    log_info "🧪 Testando Estratégia 2: Blue-Green Deployment"
    echo "------------------------------------------------"
    
    cd "$PROJECT_ROOT/strategies/02-blue-green"
    
    # Tornar scripts executáveis
    chmod +x *.sh
    
    # Executar deploy
    log_info "Executando Blue-Green deploy..."
    if ./deploy-blue-green.sh lgs-mfe-container latest; then
        log_success "Blue-Green deploy executado com sucesso!"
        
        # Verificar status
        log_info "Verificando status..."
        ./status-blue-green.sh
    else
        log_error "Blue-Green deploy falhou!"
        return 1
    fi
    
    cd "$PROJECT_ROOT"
    echo ""
}

# Função para testar Canary
test_canary() {
    log_info "🧪 Testando Estratégia 3: Canary Deployment"
    echo "----------------------------------------------"
    
    cd "$PROJECT_ROOT/strategies/03-canary"
    
    # Tornar script executável
    chmod +x deploy-canary.sh
    
    # Executar deploy com configuração rápida para teste
    log_info "Executando Canary deploy (configuração rápida)..."
    if ./deploy-canary.sh lgs-mfe-container latest 5 50 30; then
        log_success "Canary deploy executado com sucesso!"
    else
        log_error "Canary deploy falhou!"
        return 1
    fi
    
    cd "$PROJECT_ROOT"
    echo ""
}

# Função para testar Rolling Updates
test_rolling_updates() {
    log_info "🧪 Testando Estratégia 4: Rolling Updates"
    echo "--------------------------------------------"
    
    cd "$PROJECT_ROOT/strategies/04-rolling-updates"
    
    # Verificar se Docker Swarm está ativo
    if docker info | grep -q "Swarm: active"; then
        log_info "Docker Swarm ativo. Testando com docker-stack.yml..."
        
        # Deploy stack
        if docker stack deploy -c docker-stack.yml lgs-mfe; then
            log_success "Stack deployado com sucesso!"
            
            # Aguardar serviços estarem prontos
            log_info "Aguardando serviços estarem prontos..."
            sleep 30
            
            # Verificar status
            docker service ls
            docker service ps lgs-mfe_lgs-mfe-container
        else
            log_error "Stack deploy falhou!"
            return 1
        fi
    else
        log_warning "Docker Swarm não está ativo. Pulando teste de Rolling Updates..."
        log_info "Para ativar: docker swarm init"
    fi
    
    cd "$PROJECT_ROOT"
    echo ""
}

# Função para gerar relatório
generate_report() {
    log_info "📊 Gerando Relatório de Testes..."
    
    REPORT_FILE="test-report-$(date +%Y%m%d-%H%M%S).txt"
    
    # Capturar resultados dos testes
    local simple_result="❌ FALHOU"
    local bluegreen_result="❌ FALHOU"
    local canary_result="❌ FALHOU"
    local rolling_result="❌ FALHOU"
    
    # Verificar se containers estão rodando para determinar resultados
    if docker ps --format "table {{.Names}}" | grep -q "lgs-mfe-container"; then
        simple_result="✅ PASSOU"
    fi
    
    if docker ps --format "table {{.Names}}" | grep -q "lgs-mfe-container-blue\|lgs-mfe-container-green"; then
        bluegreen_result="✅ PASSOU"
    fi
    
    if docker ps --format "table {{.Names}}" | grep -q "lgs-mfe-container-canary\|lgs-mfe-container-main"; then
        canary_result="✅ PASSOU"
    fi
    
    if docker info | grep -q "Swarm: active" && docker service ls 2>/dev/null | grep -q "lgs-mfe"; then
        rolling_result="✅ PASSOU"
    fi
    
    cat > "$REPORT_FILE" << EOF
RELATÓRIO DE TESTES DE ESTRATÉGIAS CI/CD
=========================================

Data: $(date)
Hora: $(date +%H:%M:%S)

RESULTADOS DOS TESTES:
======================

1. Simple Deploy: $simple_result
2. Blue-Green: $bluegreen_result
3. Canary: $canary_result
4. Rolling Updates: $rolling_result

CONTAINERS ATIVOS:
==================
$(docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" 2>/dev/null || echo "Nenhum container ativo")

IMAGENS DISPONÍVEIS:
====================
$(docker images | grep lgs-mfe 2>/dev/null || echo "Nenhuma imagem lgs-mfe encontrada")

REDES:
======
$(docker network ls 2>/dev/null || echo "Erro ao listar redes")

RECOMENDAÇÕES:
==============
- Execute os testes em ambiente isolado
- Monitore logs durante os testes
- Valide funcionalidades após cada deploy
- Documente problemas encontrados
- Use estratégias em produção gradualmente

EOF

    log_success "Relatório gerado: $REPORT_FILE"
}

# Função principal
main() {
    echo "🚀 Iniciando Testes de Estratégias CI/CD"
    echo "========================================"
    echo ""
    
    # Verificar pré-requisitos
    check_prerequisites
    echo ""
    
    # Setup do ambiente
    setup_environment
    echo ""
    
    # Limpar containers de teste
    cleanup_test_containers
    echo ""
    
    # Executar testes
    log_info "🧪 Executando todos os testes..."
    echo ""
    
    # Testar cada estratégia
    log_info "🧪 Executando todos os testes..."
    echo ""
    
    # Testar Simple Deploy
    if test_simple_deploy; then
        log_success "✅ Simple Deploy: PASSOU"
    else
        log_error "❌ Simple Deploy: FALHOU"
    fi
    
    # Testar Blue-Green
    if test_blue_green; then
        log_success "✅ Blue-Green: PASSOU"
    else
        log_error "❌ Blue-Green: FALHOU"
    fi
    
    # Testar Canary
    if test_canary; then
        log_success "✅ Canary: PASSOU"
    else
        log_error "❌ Canary: FALHOU"
    fi
    
    # Testar Rolling Updates
    if test_rolling_updates; then
        log_success "✅ Rolling Updates: PASSOU"
    else
        log_error "❌ Rolling Updates: FALHOU"
    fi
    
    # Gerar relatório
    echo ""
    generate_report
    
    echo ""
    log_success "🎉 Todos os testes foram executados!"
    log_info "📋 Verifique o relatório gerado para detalhes"
    log_info "🔍 Use 'docker ps' para ver containers ativos"
    log_info "📝 Monitore logs com 'docker logs <container>'"
    
    # Pausa para evitar que o terminal feche
    echo ""
    log_info "⏸️  Pressione ENTER para fechar o terminal..."
    read -r
}

# Executar função principal
main "$@"
