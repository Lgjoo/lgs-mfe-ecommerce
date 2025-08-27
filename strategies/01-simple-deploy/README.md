# 🚀 Estratégia: Deploy Direto (Simple Deploy)

## 📋 **Descrição**

Estratégia mais simples de deploy que para a aplicação atual, constrói nova imagem e substitui a antiga.

## ❌ **Características**

- **Downtime**: Sim
- **Complexidade**: Baixa
- **Custo**: Baixo
- **Rollback**: Difícil
- **Segurança**: Baixa

## 🎯 **Casos de Uso**

- Ambientes de desenvolvimento
- Testes e homologação
- Aplicações não críticas
- Prototipagem rápida

## 🛠️ **Implementação**

### **Docker Compose**

```bash
# Deploy
docker-compose down
docker-compose build --no-cache
docker-compose up -d

# Rollback (manual)
docker-compose down
git checkout HEAD~1
docker-compose up -d
```

### **Docker Direto**

```bash
# Deploy
docker stop lgs-mfe-container
docker rm lgs-mfe-container
docker build -t lgs-mfe-container:latest ./lgs-mfe-container
docker run -d --name lgs-mfe-container -p 4200:4200 lgs-mfe-container:latest

# Rollback (manual)
docker stop lgs-mfe-container
docker rm lgs-mfe-container
docker run -d --name lgs-mfe-container -p 4200:4200 lgs-mfe-container:previous-version
```

### **Script Automatizado**

```bash
# Executar deploy
./deploy-simple.sh

# Executar rollback
./rollback-simple.sh previous-version
```

## ⚠️ **Limitações**

- Downtime durante deploy
- Risco de falha sem rollback automático
- Impacto direto no usuário
- Dificuldade para monitorar durante deploy

## 💡 **Melhores Práticas**

1. Execute em horários de baixo tráfego
2. Tenha backup da versão anterior
3. Teste em ambiente similar antes
4. Documente processo de rollback
5. Configure alertas de monitoramento
