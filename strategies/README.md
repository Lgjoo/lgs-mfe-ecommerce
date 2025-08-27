# 🚀 Estratégias de CI/CD - Guia de Testes

Este diretório contém todas as estratégias de CI/CD implementadas para o projeto LGS MFE E-commerce, organizadas por tipo e com scripts de teste prontos para uso.

## 📁 **Estrutura das Estratégias**

```
strategies/
├── 01-simple-deploy/          # Deploy direto (COM downtime)
├── 02-blue-green/             # Blue-Green (SEM downtime)
├── 03-canary/                 # Canary (SEM downtime)
├── 04-rolling-updates/        # Rolling Updates (SEM downtime)
└── README.md                  # Este arquivo
```

## 🎯 **Como Testar Cada Estratégia**

### **1. Simple Deploy (COM Downtime)**

```bash
cd strategies/01-simple-deploy

# Tornar scripts executáveis
chmod +x *.sh

# Testar deploy
./deploy-simple.sh lgs-mfe-container latest

# Testar rollback
./rollback-simple.sh lgs-mfe-container [versao-backup]

# Usar Docker Compose
docker-compose up -d
```

### **2. Blue-Green (SEM Downtime)**

```bash
cd strategies/02-blue-green

# Tornar scripts executáveis
chmod +x *.sh

# Deploy completo
./deploy-blue-green.sh lgs-mfe-container latest

# Verificar status
./status-blue-green.sh

# Rollback manual
./rollback-blue-green.sh lgs-mfe-container
```

### **3. Canary (SEM Downtime)**

```bash
cd strategies/03-canary

# Tornar scripts executáveis
chmod +x *.sh

# Deploy canary completo
./deploy-canary.sh lgs-mfe-container latest

# Deploy customizado
./deploy-canary.sh lgs-mfe-container v1.2.0 5 20 180

# Rollback manual
./rollback-canary.sh lgs-mfe-container
```

### **4. Rolling Updates (SEM Downtime)**

```bash
cd strategies/04-rolling-updates

# Tornar scripts executáveis
chmod +x *.sh

# Teste simulado (funciona sem Docker Swarm)
./test-rolling-updates.sh lgs-mfe-container

# Docker Swarm
docker swarm init
docker stack deploy -c docker-stack-fixed.yml lgs-mfe

# Kubernetes
kubectl apply -f k8s-deployment.yml
kubectl set image deployment/lgs-mfe-container lgs-mfe-container=lgs-mfe-container:new-version
```

## 🪟 **Para Usuários Windows**

### **Scripts Nativos do Windows:**

```cmd
# Verificação básica (CMD)
.\strategies\test-all-strategies-windows.bat

# Verificação completa (PowerShell)
.\strategies\test-all-strategies.ps1
```

### **Executar Scripts Bash no Windows:**

```bash
# Usando Git Bash
bash strategies/test-all-strategies.sh

# Usando WSL
wsl bash strategies/test-all-strategies.sh

# Usando PowerShell com Git Bash
bash strategies/test-all-strategies.sh
```

## 🛠️ **Pré-requisitos para Testes**

### **Software Necessário**

- Docker e Docker Compose
- curl (para health checks)
- bc (para cálculos matemáticos)
- kubectl (para Kubernetes)

### **Configuração Inicial**

```bash
# Criar rede Docker
docker network create mfe-network

# Verificar se aplicações estão buildadas
cd lgs-mfe-container && docker build -t lgs-mfe-container:latest .
cd ../lgs-mfe-catalog && docker build -t lgs-mfe-catalog:latest .
cd ../lgs-mfe-cart && docker build -t lgs-mfe-cart:latest .
```

## 📊 **Comparação das Estratégias para Testes**

| Estratégia      | Fácil de Testar | Recursos Necessários | Tempo de Teste | Complexidade |
| --------------- | --------------- | -------------------- | -------------- | ------------ |
| Simple Deploy   | 🟢 Sim          | 🟢 Baixo             | 🟢 Rápido      | 🟢 Baixa     |
| Blue-Green      | 🟡 Médio        | 🟡 Médio             | 🟡 Médio       | 🟡 Média     |
| Canary          | 🔴 Difícil      | 🟡 Médio             | 🔴 Lento       | 🔴 Alta      |
| Rolling Updates | 🟡 Médio        | 🟢 Baixo             | 🟡 Médio       | 🟡 Média     |

## 🧪 **Cenários de Teste Recomendados**

### **Cenário 1: Teste Básico**

1. Teste Simple Deploy primeiro
2. Valide que aplicação funciona
3. Teste rollback manual

### **Cenário 2: Teste Zero Downtime**

1. Teste Blue-Green
2. Valide que não há downtime
3. Teste rollback automático

### **Cenário 3: Teste Avançado**

1. Teste Canary com métricas
2. Valide incremento gradual
3. Teste rollback por thresholds

### **Cenário 4: Teste de Produção**

1. Teste Rolling Updates
2. Valide escalabilidade
3. Teste HPA e monitoramento

## 🔍 **Monitoramento Durante Testes**

### **Comandos Úteis**

```bash
# Ver containers rodando
docker ps

# Ver logs de um container
docker logs lgs-mfe-container

# Ver uso de recursos
docker stats

# Ver redes
docker network ls

# Ver imagens
docker images
```

### **Health Checks**

```bash
# Testar endpoint de saúde
curl -f http://localhost:4200/health

# Testar resposta da aplicação
curl http://localhost:4200/
```

## 🚨 **Solução de Problemas**

### **🔧 Correção Automática (Recomendado)**

```bash
# Corrigir automaticamente os problemas mais comuns
bash strategies/fix-common-issues.sh

# Depois executar os testes novamente
bash strategies/test-all-strategies.sh
```

### **🚀 Teste Rápido (Para Verificar Funcionamento)**

```bash
# Teste rápido que pode ser executado de qualquer diretório
bash strategies/quick-test.sh
```

### **🔍 Debug de Caminhos (Para Identificar Problemas)**

```bash
# Identificar problemas de caminhos e estrutura
bash strategies/debug-paths.sh
```

### **🔍 Diagnóstico Manual**

```bash
# Identificar problemas específicos
bash strategies/diagnose-issues.sh
```

### **Problemas Comuns e Soluções**

1. **Porta já em uso**: `docker stop $(docker ps -q)`
2. **Rede não existe**: `docker network create mfe-network`
3. **Imagem não encontrada**: Fazer build primeiro
4. **Health check falha**: Verificar se aplicação está rodando
5. **Scripts não executáveis**: `chmod +x strategies/*/*.sh`
6. **Dependências faltando**: Instalar `curl` e `bc`
7. **Docker Swarm inativo**: `docker swarm init`

### **Logs de Debug**

```bash
# Ver logs detalhados
docker logs -f lgs-mfe-container

# Ver eventos do container
docker events --filter container=lgs-mfe-container
```

## 📝 **Documentação de Testes**

### **Para Cada Teste, Documente:**

- Data e hora
- Estratégia testada
- Configurações usadas
- Resultados obtidos
- Problemas encontrados
- Tempo de execução
- Downtime observado

### **Exemplo de Relatório**

```
Teste: Blue-Green Deployment
Data: 2024-01-15 14:30
Configuração: lgs-mfe-container:latest
Resultado: ✅ Sucesso
Downtime: 0s
Tempo Total: 2m 15s
Problemas: Nenhum
```

## 🎯 **Próximos Passos**

1. **Execute os testes em ordem de complexidade**
2. **Documente todos os resultados**
3. **Identifique a melhor estratégia para seu ambiente**
4. **Implemente em produção gradualmente**
5. **Monitore e ajuste conforme necessário**

---

**💡 Dica**: Comece com Simple Deploy para validar a infraestrutura básica, depois evolua para estratégias mais avançadas conforme sua confiança e necessidades.
