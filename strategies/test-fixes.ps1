# Script PowerShell para testar se as correções de caminhos funcionaram
# Este script testa cada estratégia individualmente para verificar os caminhos

Write-Host "🧪 Testando Correções de Caminhos" -ForegroundColor Blue
Write-Host "==================================" -ForegroundColor Blue
Write-Host ""

# Detectar diretório do projeto
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$ProjectRoot = Split-Path -Parent $ScriptDir

Write-Host "🔍 Diretório do script: $ScriptDir" -ForegroundColor Yellow
Write-Host "🔍 Diretório raiz do projeto: $ProjectRoot" -ForegroundColor Yellow
Write-Host ""

# Mudar para o diretório raiz do projeto
Set-Location $ProjectRoot
Write-Host "📁 Mudando para diretório: $(Get-Location)" -ForegroundColor Green
Write-Host ""

# Verificar se rede existe
Write-Host "ℹ️  Verificando rede Docker..." -ForegroundColor Blue
$networkExists = docker network ls | Select-String "mfe-network"
if ($networkExists) {
    Write-Host "✅ Rede mfe-network já existe" -ForegroundColor Green
} else {
    Write-Host "ℹ️  Criando rede mfe-network..." -ForegroundColor Blue
    docker network create mfe-network
    Write-Host "✅ Rede criada" -ForegroundColor Green
}

# Verificar se imagens existem
Write-Host "ℹ️  Verificando imagens disponíveis..." -ForegroundColor Blue

$Images = @("lgs-mfe-container", "lgs-mfe-catalog", "lgs-mfe-cart")
$MissingImages = @()

foreach ($img in $Images) {
    $imageExists = docker images | Select-String $img
    if ($imageExists) {
        Write-Host "✅ Imagem $img encontrada" -ForegroundColor Green
    } else {
        Write-Host "⚠️  Imagem $img não encontrada" -ForegroundColor Yellow
        $MissingImages += $img
    }
}

if ($MissingImages.Count -gt 0) {
    Write-Host ""
    Write-Host "ℹ️  Para criar as imagens faltantes, execute:" -ForegroundColor Blue
    foreach ($img in $MissingImages) {
        Write-Host "   cd $img ; docker build -t $img`:latest ." -ForegroundColor White
    }
    Write-Host ""
}

# Limpar containers conflitantes
Write-Host "ℹ️  Limpando containers conflitantes..." -ForegroundColor Blue
docker stop lgs-mfe-container lgs-mfe-container-blue lgs-mfe-container-green lgs-mfe-container-canary lgs-mfe-container-main 2>$null
docker rm lgs-mfe-container lgs-mfe-container-blue lgs-mfe-container-green lgs-mfe-container-canary lgs-mfe-container-main 2>$null
Write-Host "✅ Containers conflitantes removidos" -ForegroundColor Green

Write-Host ""
Write-Host "🧪 TESTANDO ESTRATÉGIA 1: Simple Deploy" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan

Set-Location "$ProjectRoot\strategies\01-simple-deploy"

if (Test-Path "deploy-simple.sh") {
    Write-Host "ℹ️  Script encontrado, testando caminhos..." -ForegroundColor Blue
    
    # Testar se o script consegue encontrar o diretório da aplicação
    $output = bash deploy-simple.sh lgs-mfe-container latest 2>&1
    if ($output -match "Construindo nova imagem") {
        Write-Host "✅ Caminhos corrigidos! Script consegue acessar lgs-mfe-container" -ForegroundColor Green
    } else {
        Write-Host "❌ Caminhos ainda com problema" -ForegroundColor Red
    }
    
    # Parar o container se foi criado
    docker stop lgs-mfe-container 2>$null
    docker rm lgs-mfe-container 2>$null
    
} else {
    Write-Host "❌ Script deploy-simple.sh não encontrado" -ForegroundColor Red
}

Write-Host ""
Write-Host "🧪 TESTANDO ESTRATÉGIA 2: Blue-Green" -ForegroundColor Cyan
Write-Host "=====================================" -ForegroundColor Cyan

Set-Location "$ProjectRoot\strategies\02-blue-green"

if (Test-Path "deploy-blue-green.sh") {
    Write-Host "ℹ️  Script encontrado, testando caminhos..." -ForegroundColor Blue
    
    # Testar se o script consegue encontrar o diretório da aplicação
    $output = bash deploy-blue-green.sh lgs-mfe-container latest 2>&1
    if ($output -match "Construindo nova imagem") {
        Write-Host "✅ Caminhos corrigidos! Script consegue acessar lgs-mfe-container" -ForegroundColor Green
    } else {
        Write-Host "❌ Caminhos ainda com problema" -ForegroundColor Red
    }
    
    # Parar containers se foram criados
    docker stop lgs-mfe-container-blue lgs-mfe-container-green 2>$null
    docker rm lgs-mfe-container-blue lgs-mfe-container-green 2>$null
    
} else {
    Write-Host "❌ Script deploy-blue-green.sh não encontrado" -ForegroundColor Red
}

Write-Host ""
Write-Host "🧪 TESTANDO ESTRATÉGIA 3: Canary" -ForegroundColor Cyan
Write-Host "=================================" -ForegroundColor Cyan

Set-Location "$ProjectRoot\strategies\03-canary"

if (Test-Path "deploy-canary.sh") {
    Write-Host "ℹ️  Script encontrado, testando caminhos..." -ForegroundColor Blue
    
    # Testar se o script consegue encontrar o diretório da aplicação
    $output = bash deploy-canary.sh lgs-mfe-container latest 2>&1
    if ($output -match "Construindo nova imagem") {
        Write-Host "✅ Caminhos corrigidos! Script consegue acessar lgs-mfe-container" -ForegroundColor Green
    } else {
        Write-Host "❌ Caminhos ainda com problema" -ForegroundColor Red
    }
    
    # Parar containers se foram criados
    docker stop lgs-mfe-container-canary lgs-mfe-container-main 2>$null
    docker rm lgs-mfe-container-canary lgs-mfe-container-main 2>$null
    
} else {
    Write-Host "❌ Script deploy-canary.sh não encontrado" -ForegroundColor Red
}

Write-Host ""
Write-Host "🧪 TESTANDO ESTRATÉGIA 4: Rolling Updates" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan

Set-Location "$ProjectRoot\strategies\04-rolling-updates"

if (Test-Path "test-rolling-updates.sh") {
    Write-Host "ℹ️  Script encontrado, testando caminhos..." -ForegroundColor Blue
    
    # Testar se o script consegue encontrar o diretório da aplicação
    $output = bash test-rolling-updates.sh lgs-mfe-container latest 2>&1
    if ($output -match "Construindo nova imagem") {
        Write-Host "✅ Caminhos corrigidos! Script consegue acessar lgs-mfe-container" -ForegroundColor Green
    } else {
        Write-Host "❌ Caminhos ainda com problema" -ForegroundColor Red
    }
    
    # Parar containers se foram criados
    docker stop lgs-mfe-container lgs-mfe-container-new lgs-mfe-container-old 2>$null
    docker rm lgs-mfe-container lgs-mfe-container-new lgs-mfe-container-old 2>$null
    
} else {
    Write-Host "❌ Script test-rolling-updates.sh não encontrado" -ForegroundColor Red
}

Write-Host ""
Write-Host "📊 RESUMO DOS TESTES" -ForegroundColor Magenta
Write-Host "====================" -ForegroundColor Magenta

Write-Host "ℹ️  Testes de caminhos concluídos!" -ForegroundColor Blue
Write-Host "ℹ️  Se todos os testes passaram, os caminhos estão corrigidos." -ForegroundColor Blue
Write-Host "ℹ️  Execute agora: bash strategies/test-all-strategies.sh" -ForegroundColor Blue

Write-Host ""
Write-Host "⏸️  Pressione ENTER para fechar..." -ForegroundColor Yellow
Read-Host
