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
