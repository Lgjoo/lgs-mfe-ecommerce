# 🐳 **Comparação dos Dockerfiles por Estratégia de CI/CD**

Este documento compara os Dockerfiles otimizados para cada estratégia de CI/CD implementada.

## 📊 **Resumo das Diferenças**

| Aspecto                 | Simple Deploy | Blue-Green | Canary      | Rolling Updates | Multi-Estratégia |
| ----------------------- | ------------- | ---------- | ----------- | --------------- | ---------------- |
| **Tamanho da Imagem**   | 🟢 Pequeno    | 🟡 Médio   | 🟡 Médio    | 🟡 Médio        | 🔴 Grande        |
| **Velocidade de Build** | 🟢 Rápido     | 🟡 Médio   | 🟡 Médio    | 🟡 Médio        | 🟡 Médio         |
| **Flexibilidade**       | 🔴 Baixa      | 🟡 Média   | 🟡 Média    | 🟡 Média        | 🟢 Alta          |
| **Manutenção**          | 🟢 Fácil      | 🟡 Média   | 🔴 Complexa | 🟡 Média        | 🟢 Fácil         |
| **Zero Downtime**       | ❌ Não        | ✅ Sim     | ✅ Sim      | ✅ Sim          | ✅ Sim           |

## 🚀 **1. Simple Deploy (COM Downtime)**

### **Características:**

- **Foco:** Simplicidade e velocidade
- **Tamanho:** Menor imagem possível
- **Build:** Mais rápido
- **Manutenção:** Mais fácil

### **Dockerfile:**

```dockerfile
# Dockerfile para Simple Deploy - Estratégia COM Downtime
# Foco: Simplicidade e velocidade de build

FROM node:22-alpine AS builder
ENV NODE_ENV=production
ENV NPM_CONFIG_PRODUCTION=false

WORKDIR /app
COPY package*.json ./
RUN npm ci --only=production

COPY . .
RUN npm run build

FROM nginx:alpine
RUN apk add --no-cache curl

COPY --from=builder /app/dist/lgs-mfe-container /usr/share/nginx/html
RUN rm /etc/nginx/conf.d/default.conf
COPY nginx.conf /etc/nginx/conf.d/default.conf.template

COPY start.sh /start.sh
RUN chmod +x /start.sh

HEALTHCHECK --interval=30s --timeout=10s --start-period=40s --retries=3 \
    CMD curl -f http://localhost/health || exit 1

EXPOSE 4200
CMD ["/start.sh"]
```

### **Vantagens:**

✅ Build mais rápido  
✅ Imagem menor  
✅ Menos complexidade  
✅ Fácil de debugar

### **Desvantagens:**

❌ Sem zero downtime  
❌ Sem rollback automático  
❌ Menos flexibilidade

---

## 🔵 **2. Blue-Green Deployment (SEM Downtime)**

### **Características:**

- **Foco:** Zero downtime e rollback rápido
- **Tamanho:** Médio
- **Build:** Médio
- **Manutenção:** Média

### **Dockerfile:**

```dockerfile
# Dockerfile para Blue-Green Deployment - Estratégia SEM Downtime
# Foco: Zero downtime e rollback rápido

FROM node:22-alpine AS builder
ENV NODE_ENV=production
ENV NPM_CONFIG_PRODUCTION=false

WORKDIR /app
COPY package*.json ./
RUN npm ci --only=production

COPY . .
RUN npm run build

FROM nginx:alpine
RUN apk add --no-cache curl jq

COPY --from=builder /app/dist/lgs-mfe-container /usr/share/nginx/html
RUN rm /etc/nginx/conf.d/default.conf
COPY nginx.conf /etc/nginx/conf.d/default.conf.template

COPY start.sh /start.sh
COPY health-check.sh /health-check.sh
COPY switch-traffic.sh /switch-traffic.sh
RUN chmod +x /start.sh /health-check.sh /switch-traffic.sh

HEALTHCHECK --interval=15s --timeout=5s --start-period=30s --retries=5 \
    CMD /health-check.sh

EXPOSE 4200
CMD ["/start.sh"]
```

### **Vantagens:**

✅ Zero downtime  
✅ Rollback rápido  
✅ Health checks rigorosos  
✅ Scripts de switching

### **Desvantagens:**

❌ Imagem maior  
❌ Mais complexo  
❌ Requer infraestrutura adicional

---

## 🐦 **3. Canary Deployment (SEM Downtime)**

### **Características:**

- **Foco:** Deploy gradual com monitoramento avançado
- **Tamanho:** Médio
- **Build:** Médio
- **Manutenção:** Complexa

### **Dockerfile:**

```dockerfile
# Dockerfile para Canary Deployment - Estratégia SEM Downtime
# Foco: Deploy gradual com monitoramento avançado

FROM node:22-alpine AS builder
ENV NODE_ENV=production
ENV NPM_CONFIG_PRODUCTION=false

WORKDIR /app
COPY package*.json ./
RUN npm ci --only=production

COPY . .
RUN npm run build

FROM nginx:alpine
RUN apk add --no-cache curl jq bc

COPY --from=builder /app/dist/lgs-mfe-container /usr/share/nginx/html
RUN rm /etc/nginx/conf.d/default.conf
COPY nginx.conf /etc/nginx/conf.d/default.conf.template

COPY start.sh /start.sh
COPY canary-monitor.sh /canary-monitor.sh
COPY traffic-splitter.sh /traffic-splitter.sh
COPY metrics-collector.sh /metrics-collector.sh
RUN chmod +x /start.sh /canary-monitor.sh /traffic-splitter.sh /metrics-collector.sh

HEALTHCHECK --interval=10s --timeout=3s --start-period=20s --retries=3 \
    CMD /canary-monitor.sh

EXPOSE 4200
CMD ["/start.sh"]
```

### **Vantagens:**

✅ Deploy gradual  
✅ Monitoramento avançado  
✅ Rollback automático por métricas  
✅ Zero downtime

### **Desvantagens:**

❌ Imagem maior  
❌ Mais complexo  
❌ Requer monitoramento avançado  
❌ Manutenção complexa

---

## 🔄 **4. Rolling Updates (SEM Downtime)**

### **Características:**

- **Foco:** Atualizações incrementais com múltiplas réplicas
- **Tamanho:** Médio
- **Build:** Médio
- **Manutenção:** Média

### **Dockerfile:**

```dockerfile
# Dockerfile para Rolling Updates - Estratégia SEM Downtime
# Foco: Atualizações incrementais com múltiplas réplicas

FROM node:22-alpine AS builder
ENV NODE_ENV=production
ENV NPM_CONFIG_PRODUCTION=false

WORKDIR /app
COPY package*.json ./
RUN npm ci --only=production

COPY . .
RUN npm run build

FROM nginx:alpine
RUN apk add --no-cache curl jq

COPY --from=builder /app/dist/lgs-mfe-container /usr/share/nginx/html
RUN rm /etc/nginx/conf.d/default.conf
COPY nginx.conf /etc/nginx/conf.d/default.conf.template

COPY start.sh /start.sh
COPY rolling-monitor.sh /rolling-monitor.sh
COPY graceful-shutdown.sh /graceful-shutdown.sh
RUN chmod +x /start.sh /rolling-monitor.sh /graceful-shutdown.sh

HEALTHCHECK --interval=20s --timeout=8s --start-period=35s --retries=4 \
    CMD /rolling-monitor.sh

EXPOSE 4200
CMD ["/start.sh"]
```

### **Vantagens:**

✅ Zero downtime  
✅ Atualizações incrementais  
✅ Graceful shutdown  
✅ Health checks balanceados

### **Desvantagens:**

❌ Imagem maior  
❌ Requer múltiplas réplicas  
❌ Mais complexo que Simple Deploy

---

## 🚀 **5. Multi-Estratégia (Recomendado)**

### **Características:**

- **Foco:** Flexibilidade e compatibilidade com todas as estratégias
- **Tamanho:** Grande
- **Build:** Médio
- **Manutenção:** Fácil

### **Dockerfile:**

```dockerfile
# Dockerfile Multi-Estratégia - Suporta todas as estratégias de CI/CD
# Foco: Flexibilidade e compatibilidade com diferentes abordagens

FROM node:22-alpine AS builder
ENV NODE_ENV=production
ENV NPM_CONFIG_PRODUCTION=false

WORKDIR /app
COPY package*.json ./
RUN npm ci --only=production

COPY . .
RUN npm run build

FROM nginx:alpine
RUN apk add --no-cache curl jq bc && rm -rf /var/cache/apk/*

COPY --from=builder /app/dist/lgs-mfe-container /usr/share/nginx/html
RUN rm /etc/nginx/conf.d/default.conf
COPY nginx.conf /etc/nginx/conf.d/default.conf.template

COPY start.sh /start.sh
COPY health-check.sh /health-check.sh
COPY strategies/01-simple-deploy/simple-deploy.sh /scripts/simple-deploy.sh
COPY strategies/02-blue-green/blue-green-deploy.sh /scripts/blue-green-deploy.sh
COPY strategies/03-canary/canary-deploy.sh /scripts/canary-deploy.sh
COPY strategies/04-rolling-updates/rolling-deploy.sh /scripts/rolling-deploy.sh
RUN chmod +x /start.sh /health-check.sh /scripts/*.sh

HEALTHCHECK --interval=30s --timeout=10s --start-period=40s --retries=3 \
    CMD /health-check.sh

EXPOSE 4200
CMD ["/start.sh"]
```

### **Vantagens:**

✅ Suporta todas as estratégias  
✅ Fácil de manter  
✅ Flexibilidade total  
✅ Migração entre estratégias

### **Desvantagens:**

❌ Imagem maior  
❌ Build mais lento  
❌ Mais ferramentas instaladas

---

## 🎯 **Recomendações por Cenário**

### **🟢 Desenvolvimento/Testes:**

- **Use:** Simple Deploy
- **Motivo:** Mais rápido e simples

### **🟡 Staging/QA:**

- **Use:** Blue-Green ou Rolling Updates
- **Motivo:** Zero downtime para testes

### **🔴 Produção:**

- **Use:** Multi-Estratégia
- **Motivo:** Flexibilidade para mudar estratégias

### **🟠 Migração:**

- **Use:** Multi-Estratégia
- **Motivo:** Suporta todas as abordagens

---

## 📝 **Como Usar**

### **1. Build da Imagem:**

```bash
# Simple Deploy
docker build -f strategies/01-simple-deploy/Dockerfile.simple -t lgs-mfe-container:simple .

# Blue-Green
docker build -f strategies/02-blue-green/Dockerfile.blue-green -t lgs-mfe-container:blue-green .

# Canary
docker build -f strategies/03-canary/Dockerfile.canary -t lgs-mfe-container:canary .

# Rolling Updates
docker build -f strategies/04-rolling-updates/Dockerfile.rolling -t lgs-mfe-container:rolling .

# Multi-Estratégia (Recomendado)
docker build -f strategies/Dockerfile.multi-strategy -t lgs-mfe-container:multi .
```

### **2. Executar Container:**

```bash
# Simple Deploy
docker run -d --name lgs-mfe-container -p 4200:4200 lgs-mfe-container:simple

# Blue-Green
docker run -d --name lgs-mfe-container-blue -p 4200:4200 lgs-mfe-container:blue-green

# Canary
docker run -d --name lgs-mfe-container-canary -p 4201:4200 lgs-mfe-container:canary

# Rolling Updates
docker run -d --name lgs-mfe-container-rolling -p 4200:4200 lgs-mfe-container:rolling

# Multi-Estratégia
docker run -d --name lgs-mfe-container-multi -p 4200:4200 lgs-mfe-container:multi
```

---

**💡 Dica:** Comece com o Dockerfile Multi-Estratégia para ter flexibilidade total, depois otimize para estratégias específicas conforme suas necessidades evoluem.
