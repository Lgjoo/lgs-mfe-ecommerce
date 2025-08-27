# Teste do Ambiente GitHub Pages para Micro Frontends
# Script de Teste Cientifico

Write-Host "TESTE DO AMBIENTE GITHUB PAGES" -ForegroundColor Cyan
Write-Host "=====================================" -ForegroundColor Cyan
Write-Host ""

# Verificar estrutura de arquivos
Write-Host "Verificando estrutura de arquivos..." -ForegroundColor Yellow

$docsPath = "docs"
$requiredFiles = @(
    "index.html",
    "health.html", 
    "status.html",
    "metrics.html",
    "README.md"
)

$requiredFolders = @(
    ".github\workflows"
)

$workflowFiles = @(
    ".github\workflows\build-mfe.yml",
    ".github\workflows\deploy-with-downtime.yml"
)

# Verificar arquivos na pasta docs
Write-Host "`nVerificando arquivos em docs/:" -ForegroundColor Green
foreach ($file in $requiredFiles) {
    $filePath = Join-Path $docsPath $file
    if (Test-Path $filePath) {
        Write-Host "  OK $file" -ForegroundColor Green
    } else {
        Write-Host "  ERRO $file" -ForegroundColor Red
    }
}

# Verificar pastas
Write-Host "`nVerificando pastas:" -ForegroundColor Green
foreach ($folder in $requiredFolders) {
    if (Test-Path $folder) {
        Write-Host "  OK $folder" -ForegroundColor Green
    } else {
        Write-Host "  ERRO $folder" -ForegroundColor Red
    }
}

# Verificar workflows
Write-Host "`nVerificando workflows:" -ForegroundColor Green
foreach ($workflow in $workflowFiles) {
    if (Test-Path $workflow) {
        Write-Host "  OK $workflow" -ForegroundColor Green
    } else {
        Write-Host "  ERRO $workflow" -ForegroundColor Red
    }
}

# Verificar estrutura dos MFEs
Write-Host "`nVerificando estrutura dos MFEs:" -ForegroundColor Green
$mfeProjects = @("lgs-mfe-container", "lgs-mfe-catalog", "lgs-mfe-cart")

foreach ($mfe in $mfeProjects) {
    if (Test-Path $mfe) {
        Write-Host "  OK $mfe" -ForegroundColor Green
        
        # Verificar package.json
        $packagePath = Join-Path $mfe "package.json"
        if (Test-Path $packagePath) {
            Write-Host "    package.json encontrado" -ForegroundColor Green
        } else {
            Write-Host "    package.json nao encontrado" -ForegroundColor Red
        }
        
        # Verificar angular.json
        $angularPath = Join-Path $mfe "angular.json"
        if (Test-Path $angularPath) {
            Write-Host "    angular.json encontrado" -ForegroundColor Green
        } else {
            Write-Host "    angular.json nao encontrado" -ForegroundColor Red
        }
    } else {
        Write-Host "  ERRO $mfe" -ForegroundColor Red
    }
}

# Verificar configuração do Git
Write-Host "`nVerificando configuracao do Git:" -ForegroundColor Green
if (Test-Path ".git") {
    Write-Host "  OK Repositorio Git configurado" -ForegroundColor Green
    
    # Verificar remote
    try {
        $remote = git remote get-url origin 2>$null
        if ($remote) {
            Write-Host "  Remote origin: $remote" -ForegroundColor Green
        } else {
            Write-Host "  Remote origin nao configurado" -ForegroundColor Yellow
        }
    } catch {
        Write-Host "  Erro ao verificar remote" -ForegroundColor Red
    }
} else {
    Write-Host "  ERRO Repositorio Git nao configurado" -ForegroundColor Red
}

# Instruções para configuração
Write-Host "`nINSTRUCOES PARA CONFIGURACAO:" -ForegroundColor Cyan
Write-Host "=====================================" -ForegroundColor Cyan

Write-Host "`n1. Configurar GitHub Pages:" -ForegroundColor Yellow
Write-Host "   - Va para Settings → Pages" -ForegroundColor White
Write-Host "   - Source: Deploy from a branch" -ForegroundColor White
Write-Host "   - Branch: main" -ForegroundColor White
Write-Host "   - Folder: / (root)" -ForegroundColor White

Write-Host "`n2. Fazer primeiro commit:" -ForegroundColor Yellow
Write-Host "   git add ." -ForegroundColor White
Write-Host "   git commit -m 'Setup GitHub Pages para teste cientifico'" -ForegroundColor White
Write-Host "   git push origin main" -ForegroundColor White

Write-Host "`n3. Executar primeiro teste:" -ForegroundColor Yellow
Write-Host "   - Va para Actions no GitHub" -ForegroundColor White
Write-Host "   - Execute 'Deploy COM Downtime'" -ForegroundColor White
Write-Host "   - Configure downtime_duration: 180" -ForegroundColor White

Write-Host "`n4. Configurar UptimeRobot:" -ForegroundColor Yellow
Write-Host "   - URL: https://[usuario].github.io/lgs-mfe-ecommerce/" -ForegroundColor White
Write-Host "   - Health: https://[usuario].github.io/lgs-mfe-ecommerce/health.html" -ForegroundColor White
Write-Host "   - Intervalo: 1 minuto" -ForegroundColor White

Write-Host "`n5. URLs finais:" -ForegroundColor Yellow
Write-Host "   - Principal: https://[usuario].github.io/lgs-mfe-ecommerce/" -ForegroundColor White
Write-Host "   - Container: https://[usuario].github.io/lgs-mfe-ecommerce/container/" -ForegroundColor White
Write-Host "   - Catalog: https://[usuario].github.io/lgs-mfe-ecommerce/catalog/" -ForegroundColor White
Write-Host "   - Cart: https://[usuario].github.io/lgs-mfe-ecommerce/cart/" -ForegroundColor White

# Resumo do teste
Write-Host "`nRESUMO DO TESTE:" -ForegroundColor Cyan
Write-Host "===================" -ForegroundColor Cyan

$totalFiles = $requiredFiles.Count + $workflowFiles.Count
$foundFiles = 0

foreach ($file in $requiredFiles) {
    if (Test-Path (Join-Path $docsPath $file)) { $foundFiles++ }
}

foreach ($workflow in $workflowFiles) {
    if (Test-Path $workflow) { $foundFiles++ }
}

$percentage = [math]::Round(($foundFiles / $totalFiles) * 100, 1)

Write-Host "`nResultado: $foundFiles/$totalFiles arquivos encontrados ($percentage%)" -ForegroundColor $(if ($percentage -ge 80) { "Green" } elseif ($percentage -ge 60) { "Yellow" } else { "Red" })

if ($percentage -ge 80) {
    Write-Host "Ambiente configurado corretamente!" -ForegroundColor Green
    Write-Host "Pronto para testes cientificos!" -ForegroundColor Green
} elseif ($percentage -ge 60) {
    Write-Host "Ambiente parcialmente configurado" -ForegroundColor Yellow
    Write-Host "Verifique os arquivos faltantes" -ForegroundColor Yellow
} else {
    Write-Host "Ambiente com problemas" -ForegroundColor Red
    Write-Host "Configure os arquivos necessarios" -ForegroundColor Red
}

Write-Host "`nPressione qualquer tecla para continuar..." -ForegroundColor Cyan
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
