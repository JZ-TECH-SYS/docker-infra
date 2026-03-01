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

# Diagnosticar performance/instabilidade local (mounts, mysql tuning, dns, cpu/mem)
./doctor.sh

# Diagnosticar e tentar corrigir automaticamente (recria apenas serviços inconsistentes)
./doctor.sh --fix

# Subir monitor contínuo (sobe junto com docker-compose da infra)
docker-compose up -d infra_monitor

# Ver monitor em tempo real
docker-compose logs -f infra_monitor

# Ver logs persistidos do monitor
ls -lah ./monitor-logs

# Acompanhar log do dia
tail -f ./monitor-logs/doctor-monitor-$(date +%F).log

# Ver apenas incidentes detectados
tail -f ./monitor-logs/doctor-incidents-$(date +%F).log
