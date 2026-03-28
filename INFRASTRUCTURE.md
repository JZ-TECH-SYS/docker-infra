# 🐳 Infraestrutura Docker

## 📍 Localização

A infraestrutura Docker (MySQL + phpMyAdmin + Imagem API) está **centralizada** em:

```
C:\laragon\www\docker-infra\
├── Dockerfile            ← Imagem api_mvc:latest
├── docker-compose.yml    ← MySQL + phpMyAdmin
├── BUILD.md              ← Como buildar a imagem
└── mysql/
```

---

## 🚀 Início Rápido

### Opção A: Rodar API Local (Recomendado para desenvolvimento)

```powershell
# 1. Subir apenas MySQL + phpMyAdmin
cd C:\laragon\www\docker-infra
docker-compose up -d

# 2. Configure api\.env
DB_HOST=localhost
DB_PORT=3307
DB_NAME=clickexpress

# 3. Rode no Laragon/Apache normalmente
```

### Opção B: Rodar API no Docker (Isolado)

```powershell
# 1. Buildar imagem (primeira vez)
cd C:\laragon\www\docker-infra
docker build -t api_mvc:latest .

# 2. Subir infraestrutura
docker-compose up -d

# 3. Subir API no Docker
cd C:\laragon\www\ClickExpress
.\docker.ps1 start
```

---

## 🌐 URLs

- **API:** http://localhost:8089 (se rodar no Docker)
- **phpMyAdmin:** http://localhost:8090
- **Web:** http://localhost:5173 (npm run dev)

---

## 📚 Documentação Completa

Veja: `C:\laragon\www\docker-infra\README.md`

---

## � Comandos do Projeto

Este projeto tem um script helper: **`docker.ps1`**

```powershell
# Ver todos os comandos
.\docker.ps1 help

# Iniciar tudo (infra + API)
.\docker.ps1 start

# Iniciar apenas infraestrutura
.\docker.ps1 start-infra

# Iniciar apenas API
.\docker.ps1 start-api

# Parar tudo
.\docker.ps1 stop

# Ver status
.\docker.ps1 status

# Ver logs da API
.\docker.ps1 logs

# Entrar no container
.\docker.ps1 shell

# Instalar dependências
.\docker.ps1 composer
```

---

## 🔧 Configuração Local vs Docker

### **API Local** (Laragon/Apache)

**Arquivo:** `api\.env`

```env
DB_HOST=localhost
DB_PORT=3307     # Porta EXTERNA do Docker
DB_NAME=clickexpress
DB_USER=root
DB_PASS=root
```

### **API no Docker**

**Arquivo:** `api\.env` (mesmo arquivo!)

```env
DB_HOST=host.docker.internal  # Container acessa localhost do Windows
DB_PORT=3307
DB_NAME=clickexpress
DB_USER=root
DB_PASS=root
```

💡 **O docker-compose.yml já sobrescreve DB_HOST automaticamente!**

---

## 💡 Importante

- ✅ MySQL compartilhado com **todos os projetos**
- ✅ Cada projeto tem seu próprio **database** (`clickexpress`, `projeto2`, etc)
- ✅ Uma **única porta** para todos: `3307`
- ✅ Um **único phpMyAdmin** para todos: `http://localhost:8090`

---

**🎯 Centralizado, simples e eficiente!**

---

## ⚡ Performance WSL2/Docker (Tuning Aplicado)

### Problema Original
Lentidão intermitente ("do nada fica lento, do nada volta") causada por:
1. **`autoMemoryReclaim=gradual`** no `.wslconfig` - WSL2 devolvia page cache pro Windows periodicamente, causando stalls de I/O quando Docker/PHP precisava desses dados de volta
2. **PHP-FPM `pm=dynamic` com `max_children=100`** - cada projeto podia ter até 100 workers × 40MB = 4GB de RAM. Com 10 projetos = 40GB potencial
3. **Nenhum resource limit** nos containers - sem `mem_limit`, cada um comia RAM infinita

### Correções Aplicadas

**`.wslconfig`** (`C:\Users\jvzyz\.wslconfig`):
- `autoMemoryReclaim` REMOVIDO (era a causa principal dos stalls)
- `memory=8GB` (dá 8GB pro Windows respirar)
- `sparseVhd=true` (compacta VHD automaticamente)

**PHP-FPM** (`nginx/zz-docker.conf`):
- `pm = ondemand` (workers só existem durante requests, morrem após 10s idle)
- `pm.max_children = 10` (limite saudável para dev)

**Docker Compose** (todos os projetos):
- `mem_limit: 384m` em containers API
- `cpus: 1.5` em containers API
- MySQL: `mem_limit: 1g`, `cpus: 2.0`

**Stack**: Nginx + PHP-FPM 8.1 (migrado de Apache)
- OPcache + JIT (buffer 64MB)
- Nginx keepalive, gzip, open_file_cache
- DB_HOST: `mysql_shared` (rede interna Docker, não `host.docker.internal`)

### Monitoramento
```bash
# Monitor contínuo de latência (captura spikes)
./latency-watch.sh

# Monitor com múltiplas portas
./latency-watch.sh 8080 8081 8082

# Diagnóstico completo
./doctor.sh

# Limpar Docker (rodar periodicamente)
docker builder prune -f && docker image prune -f
```

### ⚠️ Após alterar `.wslconfig`
Reiniciar WSL é **obrigatório**:
```powershell
wsl --shutdown
# Depois reabrir terminal Ubuntu
```
