#  Templates para Novos Projetos

Esta pasta contém **templates** para facilitar a criação de novos projetos.

---

##  Arquivos Templates

```
docker-infra/
 EXEMPLO-docker-compose.yml    Template docker-compose
 EXEMPLO-docker.ps1             Template script Windows (NOVO)
 EXEMPLO-docker.sh              Template script Linux/Mac (NOVO)
```

---

##  Como Usar (Passo a Passo)

### 1 **Criar novo projeto**

```powershell
# Crie a pasta do projeto
mkdir C:\laragon\www\meu_projeto
cd C:\laragon\www\meu_projeto
mkdir api
```

### 2 **Copiar templates**

```powershell
# Copie os 3 arquivos template
Copy-Item C:\laragon\www\docker-infra\EXEMPLO-docker-compose.yml .\docker-compose.yml
Copy-Item C:\laragon\www\docker-infra\EXEMPLO-docker.ps1 .\docker.ps1
Copy-Item C:\laragon\www\docker-infra\EXEMPLO-docker.sh .\docker.sh
```

### 3 **Ajustar configurações**

Edite os 3 arquivos e substitua:

#### **docker-compose.yml:**
```yaml
# Linha 14: Mude o nome do projeto
name: meu_projeto  #  Era "meu_projeto"

# Linha 21: Mude o nome do container
container_name: meu_projeto_api  #  Era "meu_projeto_api"

# Linha 25: Mude a porta (se necessário)
ports:
  - "8091:80"  #  Use porta diferente se já tiver outro projeto

# Linha 30: Mude o database
DB_NAME: meu_projeto  #  Nome do database
```

#### **docker.ps1:**
```powershell
# Linhas 12-14: Ajuste as variáveis
$PROJETO_NOME = "MeuProjeto"          #  Nome do projeto
$CONTAINER_API = "meu_projeto_api"    #  Nome do container
$API_PORT = "8091"                    #  Porta da API
```

#### **docker.sh:**
```bash
# Linhas 15-17: Ajuste as variáveis
PROJETO_NOME="MeuProjeto"          #  Nome do projeto
CONTAINER_API="meu_projeto_api"    #  Nome do container
API_PORT="8091"                    #  Porta da API
```

### 4 **Criar database**

```powershell
# Acesse MySQL
docker exec -it mysql_shared mysql -uroot -proot

# Crie o database
CREATE DATABASE meu_projeto;
EXIT;
```

### 5 **Configurar .env da API**

```env
# api/.env
DB_HOST=localhost
DB_PORT=3307
DB_NAME=meu_projeto  #  Nome do database criado
DB_USER=root
DB_PASS=root
```

### 6 **Subir o projeto**

```powershell
# Windows
.\docker.ps1 start

# Linux/Mac (primeiro dar permissão)
chmod +x docker.sh
./docker.sh start
```

---

##  Exemplo Completo: Projeto2

### **Criar estrutura:**

```powershell
mkdir C:\laragon\www\projeto2
cd C:\laragon\www\projeto2
mkdir api

Copy-Item C:\laragon\www\docker-infra\EXEMPLO-docker-compose.yml .\docker-compose.yml
Copy-Item C:\laragon\www\docker-infra\EXEMPLO-docker.ps1 .\docker.ps1
Copy-Item C:\laragon\www\docker-infra\EXEMPLO-docker.sh .\docker.sh
```

### **Editar docker-compose.yml:**

```yaml
name: projeto2

services:
  api:
    image: api_mvc:latest
    container_name: projeto2_api
    volumes:
      - ./api:/var/www/html
    ports:
      - "8091:80"  #  Porta diferente!
    environment:
      DB_HOST: host.docker.internal
      DB_PORT: 3307
      DB_NAME: projeto2  #  Database diferente!
      DB_USER: root
      DB_PASS: root
    # ... resto igual
```

### **Editar docker.ps1:**

```powershell
$PROJETO_NOME = "Projeto2"
$CONTAINER_API = "projeto2_api"
$API_PORT = "8091"
```

### **Editar docker.sh:**

```bash
PROJETO_NOME="Projeto2"
CONTAINER_API="projeto2_api"
API_PORT="8091"
```

### **Criar database:**

```sql
CREATE DATABASE projeto2;
```

### **Configurar api/.env:**

```env
DB_HOST=localhost
DB_PORT=3307
DB_NAME=projeto2
DB_USER=root
DB_PASS=root
```

### **Rodar:**

```powershell
.\docker.ps1 start
```

---

##  Resumo de Portas

Mantenha um controle das portas usadas:

| Projeto      | API Port | Container       | Database       |
|--------------|----------|-----------------|----------------|
| ClickExpress | 8089     | clickexpress_api| clickexpress   |
| Projeto2     | 8091     | projeto2_api    | projeto2       |
| Projeto3     | 8092     | projeto3_api    | projeto3       |
| Projeto4     | 8093     | projeto4_api    | projeto4       |

---

##  Checklist

Antes de subir um novo projeto, verifique:

- [ ] Nome do projeto ajustado em docker-compose.yml (`name:`)
- [ ] Nome do container ajustado (`container_name:`)
- [ ] Porta diferente dos outros projetos (`ports:`)
- [ ] Database ajustado (`DB_NAME:`)
- [ ] Variáveis ajustadas no docker.ps1
- [ ] Variáveis ajustadas no docker.sh
- [ ] Database criado no MySQL
- [ ] .env da API configurado
- [ ] Permissão de execução no docker.sh (Linux/Mac): `chmod +x docker.sh`

---

##  Dicas

### **Múltiplos projetos ao mesmo tempo:**

```powershell
# Infraestrutura (uma vez)
cd C:\laragon\www\docker-infra
docker-compose up -d

# Projeto 1
cd C:\laragon\www\ClickExpress
.\docker.ps1 start-api

# Projeto 2
cd C:\laragon\www\projeto2
.\docker.ps1 start-api

# Projeto 3
cd C:\laragon\www\projeto3
.\docker.ps1 start-api
```

Todos usando o **mesmo MySQL** (porta 3307)!

---

##  Troubleshooting

### Porta já em uso

```powershell
# Veja quem está usando
netstat -ano | findstr :8091

# Mude a porta no docker-compose.yml
ports:
  - "8092:80"  # Usa outra porta
```

### Container não sobe

```powershell
# Veja os logs
docker-compose logs

# Verifique se a imagem existe
docker images | findstr api_mvc
```

### Database não conecta

```powershell
# Teste a conexão
docker exec -it mysql_shared mysql -uroot -proot -e "SHOW DATABASES;"

# Verifique se o database existe
# Se não, crie: CREATE DATABASE meu_projeto;
```

---

** Pronto! Templates configurados para facilitar novos projetos!**
