# 🧪 Teste Científico: Micro Frontends no GitHub Pages

Este diretório contém os arquivos para o GitHub Pages que servem os Micro Frontends reais (Angular) para testes científicos de estratégias CI/CD.

## 📁 Estrutura dos Arquivos

```
docs/
├── index.html          # Página principal com navegação
├── health.html         # Health check para UptimeRobot
├── status.html         # Status detalhado dos MFEs
├── metrics.html        # Métricas do teste científico
├── container/          # MFE Container (Angular buildado)
├── catalog/            # MFE Catalog (Angular buildado)
├── cart/               # MFE Cart (Angular buildado)
├── version.txt         # Versão atual
└── deploy-info.txt     # Informações do último deploy
```

## 🚀 Como Funciona

### **1. Build Automático**

- GitHub Actions builda automaticamente os MFEs Angular
- Os arquivos buildados são copiados para as pastas correspondentes
- Deploy automático para GitHub Pages

### **2. Acesso aos MFEs**

- **Container**: `https://[usuario].github.io/lgs-mfe-ecommerce/container/`
- **Catalog**: `https://[usuario].github.io/lgs-mfe-ecommerce/catalog/`
- **Cart**: `https://[usuario].github.io/lgs-mfe-ecommerce/cart/`

### **3. Monitoramento**

- **Health Check**: `https://[usuario].github.io/lgs-mfe-ecommerce/health.html`
- **Status**: `https://[usuario].github.io/lgs-mfe-ecommerce/status.html`
- **Métricas**: `https://[usuario].github.io/lgs-mfe-ecommerce/metrics.html`

## 🧪 Testes Científicos

### **Simple Deploy (COM Downtime)**

- Deploy direto com parada da aplicação
- Downtime esperado: 3-5 minutos
- UptimeRobot detecta interrupção

### **Blue-Green Deploy (SEM Downtime)**

- Deploy paralelo com switch automático
- Downtime esperado: 0-30 segundos
- UptimeRobot mantém uptime

## 📊 Configuração UptimeRobot

### **Monitor Principal**

```
URL: https://[usuario].github.io/lgs-mfe-ecommerce/
Tipo: HTTP(S)
Intervalo: 1 minuto
Alertas: Email + Webhook
```

### **Health Check**

```
URL: https://[usuario].github.io/lgs-mfe-ecommerce/health.html
Tipo: HTTP(S)
Intervalo: 1 minuto
Alertas: Email
```

## 🔧 Deploy Manual com Downtime

Para executar testes científicos:

1. **GitHub Actions** → **🛑 Deploy COM Downtime**
2. **Configure:**
   - `downtime_duration`: 180 (3 minutos)
   - `mfe_target`: all
3. **Execute** o workflow
4. **Monitore** UptimeRobot para detectar downtime

## 📈 Métricas Coletadas

- **Uptime/Downtime** por estratégia
- **Response Time** durante deploys
- **MTTR** (Mean Time To Recovery)
- **Comparação** entre estratégias
- **Análise estatística** dos resultados

## 🎯 Objetivos da Pesquisa

1. **Quantificar** downtime entre estratégias
2. **Comparar** eficiência de diferentes abordagens
3. **Validar** teorias sobre zero-downtime
4. **Fornecer** dados para tomada de decisão

## 📚 Documentação

- **Estratégias**: Ver `strategies/` no repositório principal
- **Workflows**: Ver `.github/workflows/`
- **Código**: Ver `lgs-mfe-*/` para cada MFE

---

**🧪 Projeto de Pesquisa Científica - Análise de Downtime em Estratégias CI/CD**
