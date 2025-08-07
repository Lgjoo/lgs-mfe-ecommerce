@echo off
echo 🚀 Iniciando todos os microfrontends...

echo 📚 Iniciando lgs-mfe-catalog...
cd lgs-mfe-catalog
docker-compose up -d --build

echo 🛒 Iniciando lgs-mfe-cart...
cd ..\lgs-mfe-cart
docker-compose up -d --build

echo ⏳ Aguardando microfrontends remotos...
timeout /t 10 /nobreak >nul

echo 🏠 Iniciando lgs-mfe-container...
cd ..\lgs-mfe-container
docker-compose up -d --build

echo ✅ Todos os microfrontends iniciados!
echo 🌐 Acesse: http://localhost:4200 