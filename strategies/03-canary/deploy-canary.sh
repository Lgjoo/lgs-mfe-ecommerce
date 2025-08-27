#!/bin/bash

# Canary Deployment Script - Estratégia COM Zero Downtime
# Este script implementa deploy canary para zero downtime gradual

set -e

# Detectar diretório do projeto
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$(dirname "$SCRIPT_DIR")")"

APP_NAME=${1:-"lgs-mfe-container"}
NEW_IMAGE=${2:-"latest"}
INITIAL_TRAFFIC=${3:-5}
TRAFFIC_INCREMENT=${4:-20}
WAIT_TIME=${5:-300}  # 5 minutos por padrão

echo "🐦 Iniciando Canary Deployment para $APP_NAME"
echo "📦 Nova Imagem: $NEW_IMAGE"
echo "🚦 Tráfego Inicial: ${INITIAL_TRAFFIC}%"
echo "📈 Incremento de Tráfego: ${TRAFFIC_INCREMENT}%"
echo "⏳ Tempo de Espera: ${WAIT_TIME}s entre incrementos"

# Configuração de thresholds
CPU_THRESHOLD=80
MEMORY_THRESHOLD=85
ERROR_THRESHOLD=1
RESPONSE_TIME_THRESHOLD=2000  # 2 segundos

# Função para verificar se container está rodando
check_container_running() {
    local container_name=$1
    if docker ps --format "table {{.Names}}" | grep -q "^${container_name}$"; then
        return 0
    else
        return 1
    fi
}

# Função para health check
health_check() {
    local container_name=$1
    local port=$2
    
    echo "🏥 Verificando saúde de $container_name..."
    
    # Aguardar container estar pronto
    sleep 15
    
    # Tentar health check
    if curl -f "http://localhost:$port/health" > /dev/null 2>&1; then
        echo "✅ $container_name está saudável"
        return 0
    else
        echo "❌ $container_name não está respondendo"
        return 1
    fi
}

# Função para coletar métricas
collect_metrics() {
    local container_name=$1
    local port=$2
    
    echo "📊 Coletando métricas de $container_name..."
    
    # CPU usage
    local cpu_usage=$(docker stats --no-stream --format "table {{.CPUPerc}}" "$container_name" | tail -1 | sed 's/%//')
    
    # Memory usage
    local memory_usage=$(docker stats --no-stream --format "table {{.MemPerc}}" "$container_name" | tail -1 | sed 's/%//')
    
    # Response time
    local start_time=$(date +%s%N)
    local response=$(curl -s -o /dev/null -w "%{http_code}" "http://localhost:$port/health" 2>/dev/null || echo "000")
    local end_time=$(date +%s%N)
    local response_time=$(( (end_time - start_time) / 1000000 ))  # Convert to milliseconds
    
    # Error rate (simplificado - em produção use ferramentas de APM)
    local error_rate=0
    if [ "$response" != "200" ]; then
        error_rate=100
    fi
    
    echo "   💻 CPU: ${cpu_usage}% (threshold: ${CPU_THRESHOLD}%)"
    echo "   🧠 Memória: ${memory_usage}% (threshold: ${MEMORY_THRESHOLD}%)"
    echo "   ⚡ Response Time: ${response_time}ms (threshold: ${RESPONSE_TIME_THRESHOLD}ms)"
    echo "   ❌ Error Rate: ${error_rate}% (threshold: ${ERROR_THRESHOLD}%)"
    
    # Verificar se está dentro dos thresholds
    # Usar comparação nativa do bash em vez de bc
    if [ "${cpu_usage%.*}" -gt "$CPU_THRESHOLD" ] || \
       [ "${memory_usage%.*}" -gt "$MEMORY_THRESHOLD" ] || \
       [ "$error_rate" -gt "$ERROR_THRESHOLD" ] || \
       [ "$response_time" -gt "$RESPONSE_TIME_THRESHOLD" ]; then
        echo "⚠️  Métricas fora dos thresholds aceitáveis!"
        return 1
    fi
    
    return 0
}

# Função para rollback
rollback() {
    echo "🔄 Iniciando rollback automático..."
    
    # Parar canary
    docker stop "${APP_NAME}-canary" 2>/dev/null || true
    docker rm "${APP_NAME}-canary" 2>/dev/null || true
    
    # Garantir que main está rodando
    if ! check_container_running "${APP_NAME}-main"; then
        echo "❌ Container principal não está rodando! Iniciando..."
        docker start "${APP_NAME}-main" 2>/dev/null || true
    fi
    
    echo "✅ Rollback concluído - tráfego voltou para versão principal"
    exit 1
}

# Verificar se container principal existe
if ! check_container_running "${APP_NAME}-main"; then
    echo "❌ Container principal ${APP_NAME}-main não está rodando!"
    echo "💡 Execute primeiro o deploy inicial ou blue-green"
    exit 1
fi

# Build da nova imagem
echo "🔨 Construindo nova imagem..."
cd "$PROJECT_ROOT/$APP_NAME" || exit 1
docker build -t "$APP_NAME:$NEW_IMAGE" .
cd "$PROJECT_ROOT/strategies/03-canary"

# Deploy canary
echo "🐦 Deployando versão canary..."
docker run -d \
    --name "${APP_NAME}-canary" \
    --network mfe-network \
    -p 4201:4200 \
    "$APP_NAME:$NEW_IMAGE"

# Health check inicial
echo "🏥 Verificação inicial de saúde..."
if ! health_check "${APP_NAME}-canary" "4201"; then
    echo "❌ Canary falhou no health check inicial!"
    rollback
fi

# Coletar métricas iniciais
echo "📊 Coletando métricas iniciais..."
if ! collect_metrics "${APP_NAME}-canary" "4201"; then
    echo "❌ Métricas iniciais fora dos thresholds!"
    rollback
fi

# Deploy gradual
TRAFFIC_PERCENTAGES=($INITIAL_TRAFFIC)
current_traffic=$INITIAL_TRAFFIC

while [ $current_traffic -lt 100 ]; do
    current_traffic=$((current_traffic + TRAFFIC_INCREMENT))
    if [ $current_traffic -gt 100 ]; then
        current_traffic=100
    fi
    TRAFFIC_PERCENTAGES+=($current_traffic)
done

echo "🚦 Plano de incremento de tráfego: ${TRAFFIC_PERCENTAGES[*]}%"

# Incremento gradual de tráfego
for percent in "${TRAFFIC_PERCENTAGES[@]}"; do
    echo ""
    echo "🚦 Aumentando tráfego para $percent%..."
    
    # Aqui você implementaria a lógica do load balancer
    # Por exemplo, atualizar nginx, haproxy, ou cloud load balancer
    echo "📝 Atualizando load balancer para $percent% de tráfego para canary..."
    
    # Simular atualização de load balancer
    echo "🔄 Tráfego configurado para $percent%"
    
    # Aguardar e monitorar
    echo "⏳ Aguardando $WAIT_TIME segundos para estabilização..."
    sleep $WAIT_TIME
    
    # Verificar saúde e métricas
    echo "🔍 Verificando saúde e métricas..."
    if ! health_check "${APP_NAME}-canary" "4201"; then
        echo "❌ Canary falhou no health check!"
        rollback
    fi
    
    if ! collect_metrics "${APP_NAME}-canary" "4201"; then
        echo "❌ Métricas fora dos thresholds em $percent% de tráfego!"
        rollback
    fi
    
    echo "✅ $percent% de tráfego validado com sucesso!"
done

# Deploy completo bem-sucedido
echo "🎉 Canary deployment concluído com sucesso!"

# Switch completo para nova versão
echo "🔄 Fazendo switch completo para nova versão..."

# Parar versão principal
docker stop "${APP_NAME}-main" 2>/dev/null || true
docker rm "${APP_NAME}-main" 2>/dev/null || true

# Renomear canary para main
docker rename "${APP_NAME}-canary" "${APP_NAME}-main"

# Atualizar porta para principal
docker stop "${APP_NAME}-main"
docker run -d \
    --name "${APP_NAME}-main" \
    --network mfe-network \
    -p 4200:4200 \
    "$APP_NAME:$NEW_IMAGE"

echo "✅ Deploy completo finalizado! Nova versão ativa na porta 4200"
echo "🌐 Aplicação disponível em: http://localhost:4200"

echo ""
echo "⏸️  Pressione ENTER para fechar..."
read -r
