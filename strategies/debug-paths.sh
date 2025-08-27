#!/bin/bash

# Script de Debug para Identificar Problemas de Caminhos
# Este script mostra exatamente onde estamos e o que está disponível

set -e

echo "🔍 DEBUG: Verificando Caminhos e Estrutura"
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

echo "📁 INFORMAÇÕES DE DIRETÓRIO"
echo "============================"

# Diretório atual
log_info "Diretório atual (pwd):"
echo "   $(pwd)"
echo ""

# Diretório do script
log_info "Diretório do script:"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
echo "   $SCRIPT_DIR"
echo ""

# Diretório raiz do projeto (assumindo que strategies/ está um nível acima)
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
log_info "Diretório raiz do projeto (assumido):"
echo "   $PROJECT_ROOT"
echo ""

# Verificar se PROJECT_ROOT está correto
if [ -d "$PROJECT_ROOT/lgs-mfe-container" ]; then
    log_success "✅ Diretório lgs-mfe-container encontrado em PROJECT_ROOT"
else
    log_error "❌ Diretório lgs-mfe-container NÃO encontrado em PROJECT_ROOT"
    
    # Tentar encontrar o diretório correto
    log_info "🔍 Procurando por lgs-mfe-container..."
    
    # Procurar em diretórios pais
    CURRENT_DIR="$(pwd)"
    PARENT_DIR="$(dirname "$CURRENT_DIR")"
    GRANDPARENT_DIR="$(dirname "$PARENT_DIR")"
    
    echo "   Diretório atual: $CURRENT_DIR"
    echo "   Diretório pai: $PARENT_DIR"
    echo "   Diretório avô: $GRANDPARENT_DIR"
    echo ""
    
    # Verificar cada diretório
    for dir in "$CURRENT_DIR" "$PARENT_DIR" "$GRANDPARENT_DIR"; do
        if [ -d "$dir/lgs-mfe-container" ]; then
            log_success "✅ lgs-mfe-container encontrado em: $dir"
            PROJECT_ROOT="$dir"
            break
        fi
    done
    
    if [ -z "$PROJECT_ROOT" ] || [ ! -d "$PROJECT_ROOT/lgs-mfe-container" ]; then
        log_error "❌ Não foi possível encontrar lgs-mfe-container"
        log_info "Execute este script do diretório raiz do projeto"
        exit 1
    fi
fi

echo ""

# Verificar estrutura do projeto
log_info "📂 ESTRUTURA DO PROJETO"
echo "============================"

echo "Diretório raiz confirmado: $PROJECT_ROOT"
echo ""

# Verificar diretórios principais
for dir in "lgs-mfe-container" "lgs-mfe-catalog" "lgs-mfe-cart" "strategies"; do
    if [ -d "$PROJECT_ROOT/$dir" ]; then
        log_success "✅ $dir encontrado"
    else
        log_error "❌ $dir NÃO encontrado"
    fi
done

echo ""

# Verificar estratégias
log_info "🧪 ESTRATÉGIAS DISPONÍVEIS"
echo "=============================="

if [ -d "$PROJECT_ROOT/strategies" ]; then
    cd "$PROJECT_ROOT/strategies"
    
    for strategy in "01-simple-deploy" "02-blue-green" "03-canary" "04-rolling-updates"; do
        if [ -d "$strategy" ]; then
            log_success "✅ $strategy encontrado"
            
            # Verificar scripts
            cd "$strategy"
            for script in *.sh; do
                if [ -f "$script" ]; then
                    if [ -x "$script" ]; then
                        log_success "   ✅ $script (executável)"
                    else
                        log_warning "   ⚠️  $script (não executável)"
                    fi
                fi
            done
            cd ..
        else
            log_error "❌ $strategy NÃO encontrado"
        fi
    done
    
    cd "$PROJECT_ROOT"
else
    log_error "❌ Diretório strategies não encontrado"
fi

echo ""

# Verificar Docker
log_info "🐳 VERIFICAÇÃO DO DOCKER"
echo "============================"

if command -v docker &> /dev/null; then
    log_success "✅ Docker instalado"
    
    if docker version &> /dev/null; then
        log_success "✅ Docker rodando"
        
        # Verificar rede
        if docker network ls | grep -q "mfe-network"; then
            log_success "✅ Rede mfe-network existe"
        else
            log_warning "⚠️  Rede mfe-network não existe"
        fi
        
        # Verificar imagens
        log_info "Imagens disponíveis:"
        docker images | grep "lgs-mfe" || log_warning "Nenhuma imagem lgs-mfe encontrada"
        
    else
        log_error "❌ Docker não está rodando"
    fi
else
    log_error "❌ Docker não instalado"
fi

echo ""

# Resumo e recomendações
log_info "📋 RESUMO E RECOMENDAÇÕES"
echo "============================="

echo "Para resolver os problemas de caminho:"
echo ""
echo "1. Execute os scripts do diretório raiz do projeto:"
echo "   cd $PROJECT_ROOT"
echo ""
echo "2. Ou use caminhos absolutos:"
echo "   bash $PROJECT_ROOT/strategies/test-all-strategies.sh"
echo ""
echo "3. Ou use o script de teste rápido:"
echo "   bash $PROJECT_ROOT/strategies/quick-test.sh"
echo ""

log_info "🎯 Diretório raiz correto identificado: $PROJECT_ROOT"
log_info "Execute os comandos acima para resolver os problemas de caminho"

echo ""
log_info "⏸️  Pressione ENTER para fechar..."
read -r
