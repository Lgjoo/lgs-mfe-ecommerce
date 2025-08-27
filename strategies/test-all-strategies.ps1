# Script de Teste de Estratégias CI/CD para PowerShell
# Este script verifica e testa todas as estratégias implementadas

Write-Host "🧪 Iniciando Testes de Todas as Estratégias de CI/CD" -ForegroundColor Cyan
Write-Host "=====================================================" -ForegroundColor Cyan
Write-Host ""

# Função para log colorido
function Write-LogInfo {
    param([string]$Message)
    Write-Host "ℹ️  $Message" -ForegroundColor Blue
}

function Write-LogSuccess {
    param([string]$Message)
    Write-Host "✅ $Message" -ForegroundColor Green
}

function Write-LogWarning {
    param([string]$Message)
    Write-Host "⚠️  $Message" -ForegroundColor Yellow
}

function Write-LogError {
    param([string]$Message)
    Write-Host "❌ $Message" -ForegroundColor Red
}

# Verificar se Docker está rodando
Write-LogInfo "Verificando se Docker está rodando..."
try {
    $dockerVersion = docker version 2>$null
    if ($LASTEXITCODE -eq 0) {
        Write-LogSuccess "Docker está rodando"
    } else {
        Write-LogError "Docker não está rodando! Inicie o Docker Desktop primeiro."
        Read-Host "Pressione ENTER para sair"
        exit 1
    }
} catch {
    Write-LogError "Docker não está instalado ou não está rodando"
    Read-Host "Pressione ENTER para sair"
    exit 1
}

Write-Host ""

# Criar rede se não existir
Write-LogInfo "Verificando rede mfe-network..."
$networkExists = docker network ls 2>$null | Select-String "mfe-network"
if ($networkExists) {
    Write-LogSuccess "Rede mfe-network já existe"
} else {
    Write-LogInfo "Criando rede mfe-network..."
    docker network create mfe-network 2>$null
    if ($LASTEXITCODE -eq 0) {
        Write-LogSuccess "Rede criada com sucesso!"
    } else {
        Write-LogWarning "Erro ao criar rede"
    }
}

Write-Host ""
Write-LogInfo "🧪 Verificando estratégias disponíveis..."
Write-Host ""

# Verificar Simple Deploy
Write-Host "🔴 Estratégia 1: Simple Deploy" -ForegroundColor Red
Write-Host "----------------------------------------"
$simpleScript = "strategies\01-simple-deploy\deploy-simple.sh"
if (Test-Path $simpleScript) {
    Write-LogSuccess "Script encontrado: $simpleScript"
    Write-LogInfo "Para executar: bash $simpleScript lgs-mfe-container latest"
} else {
    Write-LogError "Script não encontrado: $simpleScript"
}
Write-Host ""

# Verificar Blue-Green
Write-Host "🔵 Estratégia 2: Blue-Green Deployment" -ForegroundColor Blue
Write-Host "----------------------------------------"
$blueGreenScript = "strategies\02-blue-green\deploy-blue-green.sh"
if (Test-Path $blueGreenScript) {
    Write-LogSuccess "Script encontrado: $blueGreenScript"
    Write-LogInfo "Para executar: bash $blueGreenScript lgs-mfe-container latest"
} else {
    Write-LogError "Script não encontrado: $blueGreenScript"
}
Write-Host ""

# Verificar Canary
Write-Host "🐦 Estratégia 3: Canary Deployment" -ForegroundColor Magenta
Write-Host "----------------------------------------"
$canaryScript = "strategies\03-canary\deploy-canary.sh"
if (Test-Path $canaryScript) {
    Write-LogSuccess "Script encontrado: $canaryScript"
    Write-LogInfo "Para executar: bash $canaryScript lgs-mfe-container latest"
} else {
    Write-LogError "Script não encontrado: $canaryScript"
}
Write-Host ""

# Verificar Rolling Updates
Write-Host "🔄 Estratégia 4: Rolling Updates" -ForegroundColor Cyan
Write-Host "----------------------------------------"
$dockerStack = "strategies\04-rolling-updates\docker-stack.yml"
$k8sConfig = "strategies\04-rolling-updates\k8s-deployment.yml"

if (Test-Path $dockerStack) {
    Write-LogSuccess "Docker Stack encontrado: $dockerStack"
    Write-LogInfo "Para executar: docker stack deploy -c $dockerStack lgs-mfe"
} else {
    Write-LogError "Docker Stack não encontrado: $dockerStack"
}

if (Test-Path $k8sConfig) {
    Write-LogSuccess "Kubernetes config encontrado: $k8sConfig"
    Write-LogInfo "Para executar: kubectl apply -f $k8sConfig"
} else {
    Write-LogError "Kubernetes config não encontrado: $k8sConfig"
}

Write-Host ""
Write-LogInfo "📊 Verificando status atual do ambiente..."
Write-Host ""

# Ver containers ativos
Write-Host "🔍 Containers ativos:" -ForegroundColor Yellow
try {
    $containers = docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" 2>$null
    if ($containers) {
        Write-Host $containers
    } else {
        Write-LogInfo "Nenhum container ativo"
    }
} catch {
    Write-LogInfo "Nenhum container ativo"
}

Write-Host ""

# Ver imagens disponíveis
Write-Host "📦 Imagens disponíveis:" -ForegroundColor Yellow
try {
    $images = docker images | Select-String "lgs-mfe"
    if ($images) {
        Write-Host $images
    } else {
        Write-LogInfo "Nenhuma imagem lgs-mfe encontrada"
    }
} catch {
    Write-LogInfo "Nenhuma imagem lgs-mfe encontrada"
}

Write-Host ""

# Ver redes
Write-Host "🌐 Redes:" -ForegroundColor Yellow
try {
    $networks = docker network ls 2>$null
    if ($networks) {
        Write-Host $networks
    } else {
        Write-LogInfo "Erro ao listar redes"
    }
} catch {
    Write-LogInfo "Erro ao listar redes"
}

Write-Host ""
Write-LogSuccess "🎉 Verificação concluída!"
Write-Host ""

Write-Host "💡 Para executar os testes completos, use um destes comandos:" -ForegroundColor Cyan
Write-Host "   bash strategies/test-all-strategies.sh" -ForegroundColor White
Write-Host "   .\strategies\test-all-strategies-windows.bat" -ForegroundColor White
Write-Host "   .\strategies\test-all-strategies.ps1" -ForegroundColor White
Write-Host ""

Write-Host "💡 Ou execute cada estratégia individualmente:" -ForegroundColor Cyan
Write-Host "   1. bash strategies/01-simple-deploy/deploy-simple.sh" -ForegroundColor White
Write-Host "   2. bash strategies/02-blue-green/deploy-blue-green.sh" -ForegroundColor White
Write-Host "   3. bash strategies/03-canary/deploy-canary.sh" -ForegroundColor White
Write-Host "   4. docker stack deploy -c strategies/04-rolling-updates/docker-stack.yml lgs-mfe" -ForegroundColor White
Write-Host ""

Write-Host "⚠️  IMPORTANTE: Os scripts bash precisam do Git Bash ou WSL para funcionar" -ForegroundColor Yellow
Write-Host "   no Windows. Use os scripts .bat ou .ps1 para verificação básica." -ForegroundColor Yellow
Write-Host ""

Write-Host "⏸️  Pressione ENTER para fechar..." -ForegroundColor Green
Read-Host

