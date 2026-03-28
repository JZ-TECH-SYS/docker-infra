#  Docker Infra - MySQL + PostgreSQL Compartilhados

##  Propósito

Esta pasta contém a **infraestrutura compartilhada** para TODOS os projetos.

-  1 MySQL servindo múltiplos databases
-  1 phpMyAdmin para gerenciar tudo
-  1 PostgreSQL servindo múltiplos bancos
-  1 pgAdmin para gerenciar o PostgreSQL
-  Todos os projetos conectam aqui

---

##  Início Rápido

### 1 Subir infraestrutura

```powershell
cd C:\laragon\www\docker-infra
docker-compose up -d
```

### 2 Acessar os painéis

- phpMyAdmin: http://localhost:8090
   - Usuário: `root`
   - Senha: `root`
- pgAdmin: http://localhost:8092
   - Email: `admin@local.dev`
   - Senha: `root`

### 3 PostgreSQL já sobe com o banco magazine_povo

Em volume novo, o bootstrap do Postgres cria automaticamente:

- Banco: `magazine_povo`
- Usuário: `magazine_admin`
- Senha: `magazine_povo137@`
- Schema inicial: `sis`

Conexão para SQL Manager, DBeaver ou aplicação:

```text
Host: localhost
Porta: 5433
Banco: magazine_povo
Usuário: magazine_admin
Senha: magazine_povo137@
```

Se o volume do Postgres já existia antes dessa alteração, o script automático não roda de novo. Nesse caso, recrie o volume ou execute os comandos manualmente uma única vez.

### 4 Criar databases MySQL para seus projetos

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

### PostgreSQL CLI

```powershell
# Acessar PostgreSQL como admin
docker exec -it postgres_shared psql -U postgres -d postgres

# Ver bancos
\l

# Ver roles
\du

# Entrar no banco da aplicação
docker exec -it postgres_shared psql -U magazine_admin -d magazine_povo
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

Para forçar a reexecução dos scripts iniciais do PostgreSQL:

```powershell
docker-compose down
docker volume rm postgres_shared_data
docker-compose up -d postgres pgadmin
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

No PostgreSQL, o bootstrap padrão deste repositório fica em `postgres/init/01-bootstrap-magazine-povo.sql` e também só executa na primeira inicialização do volume.

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

### Ambiente local oscilando (rápido/lento)

```bash
# Diagnóstico técnico completo (mounts, MySQL tuning, DNS, CPU/memória)
./doctor.sh

# Tenta corrigir inconsistências recriando apenas os serviços afetados
./doctor.sh --fix
```

### Monitoramento contínuo com logs

O serviço `infra_monitor` sobe junto com a infraestrutura e roda `doctor.sh` em loop.

```bash
# Subir infra + monitor
docker-compose up -d

# Ver logs do container de monitoramento
docker-compose logs -f infra_monitor

# Ler logs persistidos no host
ls -lah ./monitor-logs
tail -f ./monitor-logs/doctor-monitor-$(date +%F).log
tail -f ./monitor-logs/doctor-incidents-$(date +%F).log
```

---

##  Dicas

###  **Performance no WSL (já aplicado nesta infra)**

- MySQL com tuning para desenvolvimento em `mysql/conf.d/99-dev-performance.cnf`
- Binlog desativado e flush reduzido para diminuir I/O no Docker Desktop + WSL
- Rotação de logs dos containers (`10m` x `3`) para evitar crescimento infinito

>  Atenção: o tuning prioriza velocidade local e pode perder poucos segundos de escrita em caso de desligamento forçado.

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
