#!/bin/bash

# 
#  [NOME_PROJETO] - Docker Helper (Linux/Mac)
# 
#  Template para novos projetos
# 
# Como usar:
#   1. Copie este arquivo para a raiz do seu projeto
#   2. Ajuste [NOME_PROJETO] e [nome_container]
#   3. chmod +x docker.sh
#   4. Execute: ./docker.sh start
# 

# 
#  CONFIGURAÇÕES - AJUSTE PARA SEU PROJETO
# 

PROJETO_NOME="meu_projeto"        #  Mude aqui
CONTAINER_API="meu_projeto_api"   #  Mude aqui
API_PORT="8089"                   #  Porta da API

# 

# Cores
GREEN='\033[0;32m'
CYAN='\033[0;36m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

INFRA_PATH="$(dirname "$(pwd)")/docker-infra"
PROJECT_PATH="$(pwd)"

# 
# Funções
# 

show_header() {
    echo -e "${CYAN}"
    echo ""
    echo "        $PROJETO_NOME Docker Manager           "
    echo ""
    echo -e "${NC}"
}

start_infrastructure() {
    echo -e "${YELLOW} Iniciando infraestrutura (MySQL + phpMyAdmin)...${NC}"
    cd "$INFRA_PATH"
    docker-compose up -d
    cd "$PROJECT_PATH"
    echo -e "${GREEN} Infraestrutura iniciada!${NC}"
}

start_api() {
    echo -e "${YELLOW} Iniciando API $PROJETO_NOME...${NC}"
    docker-compose up -d
    echo -e "${GREEN} API rodando em http://localhost:$API_PORT${NC}"
}

start_all() {
    start_infrastructure
    sleep 5
    start_api
    show_status
}

stop_all() {
    echo -e "${YELLOW} Parando containers...${NC}"
    docker-compose down
    cd "$INFRA_PATH"
    docker-compose down
    cd "$PROJECT_PATH"
    echo -e "${GREEN} Containers parados!${NC}"
}

restart_all() {
    echo -e "${YELLOW} Reiniciando containers...${NC}"
    docker-compose restart
    echo -e "${GREEN} Containers reiniciados!${NC}"
}

show_status() {
    echo -e "${CYAN}\n Status dos containers:${NC}"
    docker ps --filter "name=mysql_shared" --filter "name=phpmyadmin_shared" --filter "name=$CONTAINER_API" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
}

show_logs() {
    echo -e "${CYAN} Logs da API:${NC}"
    docker-compose logs -f api
}

enter_container() {
    echo -e "${YELLOW} Entrando no container da API...${NC}"
    docker exec -it "$CONTAINER_API" bash
}

run_composer() {
    echo -e "${YELLOW} Instalando dependências Composer...${NC}"
    docker exec -it "$CONTAINER_API" composer install
}

show_help() {
    show_header
    echo -e "${CYAN} Comandos disponíveis:${NC}\n"
    echo -e "${GREEN}  ./docker.sh start-infra${NC}"
    echo -e "     Inicia apenas MySQL + phpMyAdmin\n"
    echo -e "${GREEN}  ./docker.sh start-api${NC}"
    echo -e "     Inicia apenas a API\n"
    echo -e "${GREEN}  ./docker.sh start${NC}"
    echo -e "     Inicia tudo (infra + API)\n"
    echo -e "${GREEN}  ./docker.sh stop${NC}"
    echo -e "     Para todos os containers\n"
    echo -e "${GREEN}  ./docker.sh restart${NC}"
    echo -e "     Reinicia containers\n"
    echo -e "${GREEN}  ./docker.sh status${NC}"
    echo -e "     Mostra status dos containers\n"
    echo -e "${GREEN}  ./docker.sh logs${NC}"
    echo -e "     Mostra logs da API\n"
    echo -e "${GREEN}  ./docker.sh shell${NC}"
    echo -e "     Entra no container da API\n"
    echo -e "${GREEN}  ./docker.sh composer${NC}"
    echo -e "     Instala dependências Composer\n"
    echo -e "${CYAN} URLs:${NC}"
    echo -e "   API:        http://localhost:$API_PORT"
    echo -e "   phpMyAdmin: http://localhost:8090\n"
}

# 
# Execução de comandos
# 

case "${1:-help}" in
    start-infra)
        start_infrastructure
        ;;
    start-api)
        start_api
        ;;
    start)
        start_all
        ;;
    stop)
        stop_all
        ;;
    restart)
        restart_all
        ;;
    status)
        show_status
        ;;
    logs)
        show_logs
        ;;
    shell)
        enter_container
        ;;
    composer)
        run_composer
        ;;
    *)
        show_help
        ;;
esac
