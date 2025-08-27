# 🐦 Estratégia: Canary Deployment

## 📋 **Descrição**

Estratégia de deploy gradual que libera nova versão para uma pequena porcentagem de usuários, aumentando gradualmente baseado em métricas e saúde.

## ✅ **Características**

- **Downtime**: Não
- **Complexidade**: Alta
- **Custo**: Médio
- **Rollback**: Automático
- **Segurança**: Alta

## 🎯 **Casos de Uso**

- Deploy de produção crítico
- Teste de funcionalidades em produção
- Validação de performance em tráfego real
- Rollback automático baseado em métricas

## 🛠️ **Implementação**

### **Script Principal**

```bash
# Deploy canary completo
./deploy-canary.sh lgs-mfe-container latest

# Deploy com configuração customizada
./deploy-canary.sh lgs-mfe-container v1.2.0 5 10 300
```

### **Configuração de Tráfego**

```bash
# Ajustar porcentagem de tráfego
./adjust-traffic.sh 25

# Verificar distribuição de tráfego
./check-traffic.sh

# Rollback manual
./rollback-canary.sh
```

### **Monitoramento**

```bash
# Ver métricas em tempo real
./monitor-canary.sh

# Verificar saúde dos ambientes
./health-check.sh
```

## 🐦 **Como Funciona**

1. **Deploy Canary**: Nova versão é deployada em paralelo
2. **Tráfego Inicial**: Começa com pequena porcentagem (5%)
3. **Monitoramento**: Métricas são coletadas continuamente
4. **Aumento Gradual**: Tráfego aumenta baseado em saúde
5. **Rollback Automático**: Se problemas são detectados
6. **Deploy Completo**: Após validação completa

## 📊 **Vantagens**

- Reduz risco de deploy
- Permite monitoramento gradual
- Rollback automático em caso de problemas
- Validação em tráfego real
- Zero downtime

## ⚠️ **Desvantagens**

- Complexidade alta
- Requer infraestrutura de load balancing avançada
- Necessita de métricas e monitoramento robustos
- Pode ser mais lento que outras estratégias

## 🔧 **Configuração**

### **Parâmetros do Deploy**

- **Porcentagem Inicial**: 5% do tráfego
- **Incrementos**: 5% → 25% → 50% → 75% → 100%
- **Tempo de Espera**: 5 minutos entre incrementos
- **Thresholds de Saúde**: CPU < 80%, Memória < 85%, Erro < 1%

### **Métricas Monitoradas**

- **Performance**: Response time, throughput
- **Recursos**: CPU, memória, disco
- **Erros**: Taxa de erro, logs de erro
- **Negócio**: Conversões, transações

## 💡 **Melhores Práticas**

1. Configure thresholds adequados para seu ambiente
2. Monitore métricas de negócio além de infraestrutura
3. Use feature flags para funcionalidades críticas
4. Tenha plano de rollback documentado
5. Configure alertas para falhas críticas
6. Teste o processo de rollback regularmente
7. Documente decisões de deploy e rollback
