#  Docker Infra - MySQL + phpMyAdmin Compartilhado

##  Propósito

Esta pasta contém a **infraestrutura compartilhada** para TODOS os projetos.

-  1 MySQL servindo múltiplos databases
-  1 phpMyAdmin para gerenciar tudo
-  Todos os projetos conectam aqui

---

##  Início Rápido

### 1 Subir infraestrutura

```powershell
cd C:\laragon\www\docker-infra
docker-compose up -d
```

### 2 Acessar phpMyAdmin

http://localhost:8090
- Usuário: `root`
- Senha: `root`

### 3 Criar databases para seus projetos

```powershell
# Acessar MySQL CLI
docker exec -it mysql_shared mysql -uroot -proot

# Criar databases
CREATE DATABASE clickexpress;
CREATE DATABASE projeto2;
CREATE DATABASE projeto3;
EXIT;
```

---

##  Estrutura

```
C:\laragon\www\
 docker-infra/           Você está aqui
    docker-compose.yml
    README.md
    mysql/
        init/          (scripts .sql executam na primeira vez)

 ClickExpress/
    api/.env   DB_HOST=localhost, DB_PORT=3307, DB_NAME=clickexpress

 projeto2/
    api/.env   DB_HOST=localhost, DB_PORT=3307, DB_NAME=projeto2

 projeto3/
     api/.env   DB_HOST=localhost, DB_PORT=3307, DB_NAME=projeto3
```

---

##  Configurar Projetos

### ClickExpress

**Arquivo:** `C:\laragon\www\ClickExpress\api\.env`

```env
DB_HOST=localhost
DB_PORT=3307
DB_NAME=clickexpress
DB_USER=root
DB_PASS=root
```

### Projeto2

**Arquivo:** `C:\laragon\www\projeto2\api\.env`

```env
DB_HOST=localhost
DB_PORT=3307
DB_NAME=projeto2
DB_USER=root
DB_PASS=root
```

### Projeto3

**Arquivo:** `C:\laragon\www\projeto3\api\.env`

```env
DB_HOST=localhost
DB_PORT=3307
DB_NAME=projeto3
DB_USER=root
DB_PASS=root
```

---

##  Comandos Úteis

### Gerenciamento

```powershell
# Subir
docker-compose up -d

# Parar
docker-compose down

# Ver status
docker-compose ps

# Ver logs
docker-compose logs -f
```

### MySQL CLI

```powershell
# Acessar MySQL
docker exec -it mysql_shared mysql -uroot -proot

# Listar databases
SHOW DATABASES;

# Criar database
CREATE DATABASE meu_projeto;

# Remover database
DROP DATABASE meu_projeto;
```

### Backup

```powershell
# Backup de um database específico
docker exec mysql_shared mysqldump -uroot -proot clickexpress > backup_clickexpress.sql

# Backup de TODOS os databases
docker exec mysql_shared mysqldump -uroot -proot --all-databases > backup_all.sql

# Restaurar backup
docker exec -i mysql_shared mysql -uroot -proot clickexpress < backup_clickexpress.sql
```

### Manutenção

```powershell
# Limpar containers órfãos
docker system prune -f

# Remover volume ( APAGA TODOS OS DADOS)
docker-compose down
docker volume rm mysql_shared_data
docker-compose up -d
```

---

##  Scripts SQL Iniciais

Coloque arquivos `.sql` em `mysql/init/` para executar automaticamente:

**Exemplo:** `mysql/init/01-create-databases.sql`

```sql
CREATE DATABASE IF NOT EXISTS clickexpress;
CREATE DATABASE IF NOT EXISTS projeto2;
CREATE DATABASE IF NOT EXISTS projeto3;
```

**Exemplo:** `mysql/init/02-clickexpress-schema.sql`

```sql
USE clickexpress;

CREATE TABLE IF NOT EXISTS usuarios (
    id INT AUTO_INCREMENT PRIMARY KEY,
    nome VARCHAR(100),
    email VARCHAR(100)
);
```

 **Scripts só executam na PRIMEIRA vez** que o MySQL sobe!

Para reexecutar:
```powershell
docker-compose down
docker volume rm mysql_shared_data
docker-compose up -d
```

---

##  Troubleshooting

### Porta 3307 já em uso

```powershell
# Verificar quem está usando
netstat -ano | findstr :3307

# Matar processo
taskkill /PID <PID> /F

# Ou mudar porta no docker-compose.yml
ports:
  - "3308:3306"  # Usar 3308 em vez de 3307
```

### phpMyAdmin não conecta

```powershell
# Ver logs
docker-compose logs phpmyadmin

# Reiniciar
docker-compose restart phpmyadmin
```

### MySQL não sobe

```powershell
# Ver logs
docker-compose logs mysql

# Verificar healthcheck
docker inspect mysql_shared | findstr Health
```

---

##  Dicas

###  **Deixe sempre rodando**

Como é infraestrutura compartilhada, pode deixar sempre ligado:

```powershell
# Inicia com o Windows (opcional)
# Adicione ao Task Scheduler:
cd C:\laragon\www\docker-infra
docker-compose up -d
```

###  **Backups automáticos**

Crie um script PowerShell:

```powershell
# backup.ps1
$date = Get-Date -Format "yyyyMMdd_HHmmss"
docker exec mysql_shared mysqldump -uroot -proot --all-databases > "backup_$date.sql"
```

Agende no Task Scheduler para rodar diariamente.

###  **Monitoramento**

```powershell
# Ver uso de recursos
docker stats mysql_shared

# Ver conexões ativas
docker exec -it mysql_shared mysql -uroot -proot -e "SHOW PROCESSLIST;"
```

---

##  Resumo

1.  **Suba UMA VEZ** a infraestrutura: `docker-compose up -d`
2.  **Crie databases** para cada projeto
3.  **Configure .env** de cada projeto apontando para `localhost:3307`
4.  **Trabalhe normalmente** em todos os projetos
5.  **Use phpMyAdmin** para gerenciar tudo

**Simples, centralizado e eficiente!** 
