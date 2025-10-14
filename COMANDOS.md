#  Atalhos Rápidos

# Subir infraestrutura
docker-compose up -d

# Parar infraestrutura
docker-compose down

# Ver status
docker-compose ps

# Acessar MySQL
docker exec -it mysql_shared mysql -uroot -proot

# Backup de todos os databases
docker exec mysql_shared mysqldump -uroot -proot --all-databases > backup_all.sql
