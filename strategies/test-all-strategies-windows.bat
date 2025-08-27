@echo off
chcp 65001 >nul
setlocal enabledelayedexpansion

echo 🧪 Iniciando Testes de Todas as Estratégias de CI/CD
echo =====================================================
echo.

REM Verificar se Docker está rodando
docker version >nul 2>&1
if %errorlevel% neq 0 (
    echo ❌ Docker não está rodando! Inicie o Docker Desktop primeiro.
    pause
    exit /b 1
)

echo ✅ Docker está rodando
echo.

REM Criar rede se não existir
docker network ls | findstr "mfe-network" >nul 2>&1
if %errorlevel% neq 0 (
    echo ℹ️  Criando rede mfe-network...
    docker network create mfe-network
    echo ✅ Rede criada!
) else (
    echo ✅ Rede mfe-network já existe!
)

echo.
echo 🧪 Executando todos os testes...
echo.

REM Testar Simple Deploy
echo 🔴 Testando Estratégia 1: Simple Deploy
echo ----------------------------------------
cd strategies\01-simple-deploy
if exist deploy-simple.sh (
    echo ✅ Script encontrado
    echo ℹ️  Para executar: ./deploy-simple.sh lgs-mfe-container latest
) else (
    echo ❌ Script não encontrado
)
cd ..\..

echo.

REM Testar Blue-Green
echo 🔵 Testando Estratégia 2: Blue-Green Deployment
echo ------------------------------------------------
cd strategies\02-blue-green
if exist deploy-blue-green.sh (
    echo ✅ Script encontrado
    echo ℹ️  Para executar: ./deploy-blue-green.sh lgs-mfe-container latest
) else (
    echo ❌ Script não encontrado
)
cd ..\..

echo.

REM Testar Canary
echo 🐦 Testando Estratégia 3: Canary Deployment
echo --------------------------------------------
cd strategies\03-canary
if exist deploy-canary.sh (
    echo ✅ Script encontrado
    echo ℹ️  Para executar: ./deploy-canary.sh lgs-mfe-container latest
) else (
    echo ❌ Script não encontrado
)
cd ..\..

echo.

REM Testar Rolling Updates
echo 🔄 Testando Estratégia 4: Rolling Updates
echo -----------------------------------------
cd strategies\04-rolling-updates
if exist docker-stack.yml (
    echo ✅ Docker Stack encontrado
    echo ℹ️  Para executar: docker stack deploy -c docker-stack.yml lgs-mfe
) else (
    echo ❌ Docker Stack não encontrado
)

if exist k8s-deployment.yml (
    echo ✅ Kubernetes config encontrado
    echo ℹ️  Para executar: kubectl apply -f k8s-deployment.yml
) else (
    echo ❌ Kubernetes config não encontrado
)
cd ..\..

echo.
echo 📊 Verificando status atual...
echo.

REM Ver containers ativos
echo 🔍 Containers ativos:
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" 2>nul
if %errorlevel% neq 0 (
    echo ℹ️  Nenhum container ativo
)

echo.

REM Ver imagens disponíveis
echo 📦 Imagens disponíveis:
docker images | findstr "lgs-mfe" 2>nul
if %errorlevel% neq 0 (
    echo ℹ️  Nenhuma imagem lgs-mfe encontrada
)

echo.

REM Ver redes
echo 🌐 Redes:
docker network ls 2>nul
if %errorlevel% neq 0 (
    echo ℹ️  Erro ao listar redes
)

echo.
echo 🎉 Verificação concluída!
echo.
echo 💡 Para executar os testes completos, use o script bash:
echo    bash strategies/test-all-strategies.sh
echo.
echo 💡 Ou execute cada estratégia individualmente:
echo    1. cd strategies\01-simple-deploy && ./deploy-simple.sh
echo    2. cd strategies\02-blue-green && ./deploy-blue-green.sh
echo    3. cd strategies\03-canary && ./deploy-canary.sh
echo    4. cd strategies\04-rolling-updates && docker stack deploy -c docker-stack.yml lgs-mfe
echo.
echo ⏸️  Pressione qualquer tecla para fechar...
pause >nul

