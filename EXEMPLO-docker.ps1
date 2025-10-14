# 
#  [NOME_PROJETO] - Docker Helper
# 
#  Template para novos projetos
# 
# Como usar:
#   1. Copie este arquivo para a raiz do seu projeto
#   2. Ajuste [NOME_PROJETO] e [nome_container]
#   3. Execute: .\docker.ps1 start
# 

param(
    [string]$Command = "help"
)

# 
#  CONFIGURAÇÕES - AJUSTE PARA SEU PROJETO
# 

$PROJETO_NOME = "meu_projeto"        #  Mude aqui
$CONTAINER_API = "meu_projeto_api"   #  Mude aqui
$API_PORT = "8089"                   #  Porta da API

# 

$InfraPath = "C:\laragon\www\docker-infra"
$ProjectPath = $PSScriptRoot

function Show-Header {
    Write-Host "`n" -ForegroundColor Cyan
    Write-Host "        $PROJETO_NOME Docker Manager            " -ForegroundColor Cyan
    Write-Host "`n" -ForegroundColor Cyan
}

function Start-Infrastructure {
    Write-Host " Iniciando infraestrutura (MySQL + phpMyAdmin)..." -ForegroundColor Yellow
    Set-Location $InfraPath
    docker-compose up -d
    Set-Location $ProjectPath
    Write-Host " Infraestrutura iniciada!" -ForegroundColor Green
}

function Start-API {
    Write-Host " Iniciando API $PROJETO_NOME..." -ForegroundColor Yellow
    docker-compose up -d
    Write-Host " API rodando em http://localhost:$API_PORT" -ForegroundColor Green
}

function Start-All {
    Start-Infrastructure
    Start-Sleep -Seconds 5
    Start-API
    Show-Status
}

function Stop-All {
    Write-Host " Parando containers..." -ForegroundColor Yellow
    docker-compose down
    Set-Location $InfraPath
    docker-compose down
    Set-Location $ProjectPath
    Write-Host " Containers parados!" -ForegroundColor Green
}

function Show-Status {
    Write-Host "`n Status dos containers:" -ForegroundColor Cyan
    docker ps --filter "name=mysql_shared" --filter "name=phpmyadmin_shared" --filter "name=$CONTAINER_API" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
}

function Show-Logs {
    Write-Host " Logs da API:" -ForegroundColor Cyan
    docker-compose logs -f api
}

function Enter-Container {
    Write-Host " Entrando no container da API..." -ForegroundColor Yellow
    docker exec -it $CONTAINER_API bash
}

function Run-Composer {
    Write-Host " Instalando dependências Composer..." -ForegroundColor Yellow
    docker exec -it $CONTAINER_API composer install
}

function Restart-All {
    Write-Host " Reiniciando containers..." -ForegroundColor Yellow
    docker-compose restart
    Write-Host " Containers reiniciados!" -ForegroundColor Green
}

function Show-Help {
    Show-Header
    Write-Host " Comandos disponíveis:" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "  .\docker.ps1 start-infra" -ForegroundColor Green
    Write-Host "     Inicia apenas MySQL + phpMyAdmin" -ForegroundColor Gray
    Write-Host ""
    Write-Host "  .\docker.ps1 start-api" -ForegroundColor Green
    Write-Host "     Inicia apenas a API" -ForegroundColor Gray
    Write-Host ""
    Write-Host "  .\docker.ps1 start" -ForegroundColor Green
    Write-Host "     Inicia tudo (infra + API)" -ForegroundColor Gray
    Write-Host ""
    Write-Host "  .\docker.ps1 stop" -ForegroundColor Green
    Write-Host "     Para todos os containers" -ForegroundColor Gray
    Write-Host ""
    Write-Host "  .\docker.ps1 restart" -ForegroundColor Green
    Write-Host "     Reinicia containers" -ForegroundColor Gray
    Write-Host ""
    Write-Host "  .\docker.ps1 status" -ForegroundColor Green
    Write-Host "     Mostra status dos containers" -ForegroundColor Gray
    Write-Host ""
    Write-Host "  .\docker.ps1 logs" -ForegroundColor Green
    Write-Host "     Mostra logs da API" -ForegroundColor Gray
    Write-Host ""
    Write-Host "  .\docker.ps1 shell" -ForegroundColor Green
    Write-Host "     Entra no container da API" -ForegroundColor Gray
    Write-Host ""
    Write-Host "  .\docker.ps1 composer" -ForegroundColor Green
    Write-Host "     Instala dependências Composer" -ForegroundColor Gray
    Write-Host ""
    Write-Host " URLs:" -ForegroundColor Cyan
    Write-Host "   API:        http://localhost:$API_PORT" -ForegroundColor White
    Write-Host "   phpMyAdmin: http://localhost:8090" -ForegroundColor White
    Write-Host ""
}

# 
# Execução de comandos
# 

switch ($Command.ToLower()) {
    "start-infra" { Start-Infrastructure }
    "start-api" { Start-API }
    "start" { Start-All }
    "stop" { Stop-All }
    "restart" { Restart-All }
    "status" { Show-Status }
    "logs" { Show-Logs }
    "shell" { Enter-Container }
    "composer" { Run-Composer }
    default { Show-Help }
}
