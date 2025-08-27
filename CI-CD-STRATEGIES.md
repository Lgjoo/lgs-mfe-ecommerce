# 🚀 Estratégias de CI/CD com e sem Zero Downtime

Este documento descreve diferentes estratégias de Continuous Integration e Continuous Deployment para o projeto LGS MFE E-commerce.

## 📋 **Estratégias SEM Zero Downtime**

### 1. **Deploy Direto (Simple Deploy)**

- **Como funciona**: Para a aplicação atual, constrói nova imagem e substitui a antiga
- **Vantagens**: Simples, rápido, fácil de implementar
- **Desvantagens**: Downtime durante deploy, risco de falha, impacto no usuário
- **Uso recomendado**: Ambientes de desenvolvimento, testes, aplicações não críticas

```bash
# Exemplo de implementação
docker stop lgs-mfe-container
docker rm lgs-mfe-container
docker run -d --name lgs-mfe-container -p 4200:4200 lgs-mfe-container:latest
```

### 2. **Deploy com Manutenção**

- **Como funciona**: Aplica deploy durante janela de manutenção programada
- **Vantagens**: Controle total sobre quando o downtime ocorre
- **Desvantagens**: Requer planejamento, pode não ser adequado para aplicações 24/7
- **Uso recomendado**: Aplicações internas, sistemas com horários de baixo uso

## 🔄 **Estratégias COM Zero Downtime**

### 1. **Blue-Green Deployment**

- **Como funciona**:

  - Mantém duas versões idênticas (Blue e Green)
  - Deploy da nova versão na instância Green
  - Teste da Green
  - Switch de tráfego da Blue para Green
  - Desativação da Blue

- **Vantagens**: Zero downtime, rollback instantâneo, fácil de entender
- **Desvantagens**: Duplica recursos, custo maior
- **Implementação**: Ver arquivo `.github/workflows/ci-cd.yml`

```yaml
# Exemplo do workflow
- name: Deploy Green Environment
  run: |
    docker run -d --name lgs-mfe-container-green -p 4201:4200 lgs-mfe-container:green
    # Health check
    curl -f http://localhost:4201/health || exit 1
```

### 2. **Canary Deployment**

- **Como funciona**:

  - Deploy gradual da nova versão
  - Início com pequena porcentagem de tráfego (5%)
  - Aumento gradual baseado em métricas e saúde
  - Rollback automático em caso de problemas

- **Vantagens**: Reduz risco, permite monitoramento gradual, rollback automático
- **Desvantagens**: Mais complexo, requer infraestrutura de load balancing
- **Implementação**: Ver arquivo `deploy-canary.sh`

```bash
# Executar deploy canary
./deploy-canary.sh lgs-mfe-container latest
```

### 3. **Rolling Updates**

- **Como funciona**:

  - Atualiza pods/containers um por vez
  - Mantém número mínimo de instâncias disponíveis
  - Health checks garantem que apenas instâncias saudáveis recebam tráfego

- **Vantagens**: Zero downtime, uso eficiente de recursos, nativo do Kubernetes
- **Desvantagens**: Pode ser mais lento, complexidade na configuração
- **Implementação**: Ver arquivos `docker-stack.yml` e `k8s-deployment.yml`

```yaml
# Docker Swarm
update_config:
  parallelism: 1
  delay: 10s
  order: start-first
  failure_action: rollback
  monitor: 60s
  max_failure_ratio: 0.3

# Kubernetes
strategy:
  type: RollingUpdate
  rollingUpdate:
    maxSurge: 1
    maxUnavailable: 0
```

## 🛠️ **Implementação Recomendada para seu Projeto**

### **Ambiente de Desenvolvimento**

- **Estratégia**: Deploy direto
- **Justificativa**: Simplicidade, velocidade, ambiente não crítico

### **Ambiente de Staging**

- **Estratégia**: Blue-Green Deployment
- **Justificativa**: Teste completo da nova versão antes da produção

### **Ambiente de Produção**

- **Estratégia**: Canary Deployment + Rolling Updates
- **Justificativa**: Máxima segurança, zero downtime, rollback automático

## 📊 **Comparação das Estratégias**

| Estratégia      | Downtime | Complexidade | Custo    | Rollback      | Segurança |
| --------------- | -------- | ------------ | -------- | ------------- | --------- |
| Deploy Direto   | ❌ Sim   | 🟢 Baixa     | 🟢 Baixo | ❌ Difícil    | 🔴 Baixa  |
| Blue-Green      | ✅ Não   | 🟡 Média     | 🟡 Médio | 🟢 Fácil      | 🟡 Média  |
| Canary          | ✅ Não   | 🔴 Alta      | 🟡 Médio | 🟢 Automático | 🟢 Alta   |
| Rolling Updates | ✅ Não   | 🟡 Média     | 🟢 Baixo | 🟡 Médio      | 🟢 Alta   |

## 🚀 **Como Implementar**

### 1. **Setup Inicial**

```bash
# Clonar repositório
git clone https://github.com/Lgjoo/lgs-mfe-ecommerce.git
cd lgs-mfe-ecommerce

# Configurar GitHub Actions (automático via workflow)
# Configurar Docker Swarm ou Kubernetes
```

### 2. **Deploy com Docker Swarm**

```bash
# Inicializar swarm
docker swarm init

# Deploy stack
docker stack deploy -c docker-stack.yml lgs-mfe

# Atualizar serviço
docker service update --image lgs-mfe-container:new-version lgs-mfe_lgs-mfe-container
```

### 3. **Deploy com Kubernetes**

```bash
# Aplicar configuração
kubectl apply -f k8s-deployment.yml

# Atualizar imagem
kubectl set image deployment/lgs-mfe-container lgs-mfe-container=lgs-mfe-container:new-version

# Verificar status
kubectl rollout status deployment/lgs-mfe-container
```

### 4. **Deploy Canary**

```bash
# Tornar script executável
chmod +x deploy-canary.sh

# Executar deploy
./deploy-canary.sh lgs-mfe-container v1.2.0
```

## 🔍 **Monitoramento e Health Checks**

### **Métricas Importantes**

- **Disponibilidade**: Uptime, response time
- **Performance**: CPU, memória, throughput
- **Erros**: Taxa de erro, logs de erro
- **Negócio**: Conversões, transações

### **Health Check Endpoint**

```typescript
// Adicionar em cada micro frontend
@Get('/health')
async healthCheck() {
  return {
    status: 'healthy',
    timestamp: new Date().toISOString(),
    version: process.env.APP_VERSION,
    uptime: process.uptime()
  };
}
```

## 🚨 **Rollback e Recuperação**

### **Rollback Automático**

- **Health Check falha**: Rollback automático
- **Métricas degradadas**: Rollback baseado em thresholds
- **Tempo limite**: Rollback se deploy demorar muito

### **Rollback Manual**

```bash
# Docker
docker service rollback lgs-mfe_lgs-mfe-container

# Kubernetes
kubectl rollout undo deployment/lgs-mfe-container

# Canary
./deploy-canary.sh lgs-mfe-container previous-version
```

## 💡 **Dicas e Melhores Práticas**

1. **Sempre teste em staging antes da produção**
2. **Implemente health checks robustos**
3. **Monitore métricas durante e após deploy**
4. **Tenha plano de rollback documentado**
5. **Use feature flags para funcionalidades críticas**
6. **Implemente logging estruturado**
7. **Configure alertas para falhas de deploy**

## 🔗 **Recursos Adicionais**

- [GitHub Actions Documentation](https://docs.github.com/en/actions)
- [Docker Swarm Documentation](https://docs.docker.com/engine/swarm/)
- [Kubernetes Documentation](https://kubernetes.io/docs/)
- [Nginx Load Balancing](https://nginx.org/en/docs/http/load_balancing.html)

---

**Nota**: Escolha a estratégia baseada nos requisitos de disponibilidade, complexidade aceitável e recursos disponíveis. Para produção, recomendo começar com Blue-Green e evoluir para Canary conforme a maturidade da equipe.
