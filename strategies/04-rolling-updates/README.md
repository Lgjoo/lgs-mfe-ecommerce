# 🔄 Rolling Updates - Estratégia SEM Downtime

Esta estratégia implementa atualizações incrementais que permitem zero downtime durante deployments.

## 🎯 **Como Funciona**

Rolling Updates atualiza instâncias de aplicação uma por vez, garantindo que sempre haja instâncias disponíveis para servir tráfego.

## 🚀 **Como Testar**

### **Opção 1: Teste Simulado (Recomendado para Desenvolvimento)**

```bash
cd strategies/04-rolling-updates

# Tornar scripts executáveis
chmod +x *.sh

# Testar Rolling Update simulado
./test-rolling-updates.sh lgs-mfe-container

# Testar com versão específica
./test-rolling-updates.sh lgs-mfe-container v1.2.0
```

### **Opção 2: Docker Swarm (Para Produção)**

```bash
# Inicializar Docker Swarm
docker swarm init

# Deploy do stack
docker stack deploy -c docker-stack.yml lgs-mfe

# Verificar status
docker stack services lgs-mfe

# Atualizar imagem
docker service update --image lgs-mfe-container:new-version lgs-mfe_lgs-mfe-container
```

### **Opção 3: Kubernetes (Para Produção)**

```bash
# Aplicar deployment
kubectl apply -f k8s-deployment.yml

# Verificar status
kubectl get pods -l app=lgs-mfe-container

# Atualizar imagem
kubectl set image deployment/lgs-mfe-container lgs-mfe-container=lgs-mfe-container:new-version

# Verificar rollout
kubectl rollout status deployment/lgs-mfe-container
```

## 📁 **Arquivos Disponíveis**

- **`test-rolling-updates.sh`** - Script de teste simulado (funciona sem Docker Swarm)
- **`docker-stack.yml`** - Configuração para Docker Swarm
- **`docker-stack-fixed.yml`** - Versão corrigida do docker-stack.yml
- **`k8s-deployment.yml`** - Manifesto Kubernetes
- **`README.md`** - Este arquivo

## 🔧 **Configurações**

### **Docker Swarm**

- **Replicas**: 3 para container principal, 2 para outros serviços
- **Update Strategy**: 1 por vez com delay de 10s
- **Rollback**: Automático em caso de falha
- **Health Check**: Endpoint `/health` a cada 30s

### **Kubernetes**

- **Replicas**: 3
- **Strategy**: RollingUpdate com maxUnavailable: 1
- **Health Checks**: Liveness e Readiness probes
- **HPA**: Auto-scaling baseado em CPU e memória

## 📊 **Métricas Monitoradas**

- **CPU Usage**: Threshold de 80%
- **Memory Usage**: Threshold de 85%
- **Response Time**: Threshold de 2 segundos
- **Error Rate**: Threshold de 1%
- **Health Status**: Endpoint `/health`

## 🚨 **Solução de Problemas**

### **Docker Swarm não está ativo**

```bash
# Inicializar swarm
docker swarm init

# Ou verificar status
docker info | grep Swarm
```

### **Erro de sintaxe YAML**

```bash
# Usar versão corrigida
docker stack deploy -c docker-stack-fixed.yml lgs-mfe
```

### **Health check falha**

```bash
# Verificar logs
docker logs <container-name>

# Verificar endpoint
curl -f http://localhost:4200/health
```

### **Rollback manual**

```bash
# Docker Swarm
docker service rollback lgs-mfe_lgs-mfe-container

# Kubernetes
kubectl rollout undo deployment/lgs-mfe-container
```

## 💡 **Vantagens**

✅ **Zero Downtime** - Sempre há instâncias disponíveis  
✅ **Rollback Automático** - Em caso de falha  
✅ **Escalabilidade** - Fácil de escalar horizontalmente  
✅ **Monitoramento** - Health checks e métricas em tempo real

## ⚠️ **Considerações**

- **Recursos**: Requer mais recursos que Simple Deploy
- **Complexidade**: Configuração mais complexa
- **Dependências**: Docker Swarm ou Kubernetes necessários para produção

## 🎯 **Cenários de Uso**

- **Desenvolvimento**: Use `test-rolling-updates.sh`
- **Staging**: Use Docker Swarm
- **Produção**: Use Kubernetes com HPA

---

**💡 Dica**: Comece com o teste simulado para validar a lógica, depois evolua para Docker Swarm ou Kubernetes conforme suas necessidades.
