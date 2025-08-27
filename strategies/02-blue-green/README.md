# 🔄 Estratégia: Blue-Green Deployment

## 📋 **Descrição**

Estratégia que mantém duas versões idênticas (Blue e Green) e faz switch de tráfego entre elas para zero downtime.

## ✅ **Características**

- **Downtime**: Não
- **Complexidade**: Média
- **Custo**: Médio (duplica recursos)
- **Rollback**: Fácil
- **Segurança**: Média

## 🎯 **Casos de Uso**

- Ambientes de staging
- Deploy de produção
- Aplicações críticas
- Quando rollback rápido é necessário

## 🛠️ **Implementação**

### **Docker Compose**

```bash
# Deploy Blue
docker-compose -f docker-compose.blue.yml up -d

# Deploy Green
docker-compose -f docker-compose.green.yml up -d

# Switch de tráfego
./switch-traffic.sh blue green
```

### **Docker Direto**

```bash
# Deploy
./deploy-blue-green.sh lgs-mfe-container latest

# Rollback
./rollback-blue-green.sh
```

### **Script Automatizado**

```bash
# Executar deploy completo
./deploy-blue-green.sh

# Verificar status
./status-blue-green.sh

# Fazer rollback
./rollback-blue-green.sh
```

## 🔄 **Como Funciona**

1. **Blue Environment**: Versão atual em produção
2. **Green Environment**: Nova versão sendo testada
3. **Deploy**: Nova versão é deployada no Green
4. **Teste**: Green é testado e validado
5. **Switch**: Tráfego é redirecionado do Blue para Green
6. **Cleanup**: Blue é desativado

## 📊 **Vantagens**

- Zero downtime
- Rollback instantâneo
- Fácil de entender e implementar
- Teste completo antes do switch

## ⚠️ **Desvantagens**

- Duplica recursos (custo)
- Requer infraestrutura de load balancing
- Complexidade na configuração de rede

## 💡 **Melhores Práticas**

1. Use health checks robustos
2. Teste Green completamente antes do switch
3. Configure load balancer para switch rápido
4. Monitore métricas durante transição
5. Tenha plano de rollback documentado
6. Use feature flags para funcionalidades críticas
