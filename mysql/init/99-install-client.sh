#!/bin/bash
# Script de inicialização para instalar mysql-client no container MySQL

# Aguardar MySQL estar pronto
echo "Aguardando MySQL estar pronto..."
while ! mysqladmin ping -h127.0.0.1 -uroot -proot --silent 2>/dev/null; do
    echo "MySQL não está pronto ainda. Aguardando..."
    sleep 2
done

echo "MySQL está pronto!"

# Atualizar e instalar mysql-client
echo "Instalando mysql-client..."
apt-get update >/dev/null 2>&1 && apt-get install -y default-mysql-client >/dev/null 2>&1

if command -v mysqldump &> /dev/null; then
    echo "✓ mysqldump instalado com sucesso!"
else
    echo "⚠ Não foi possível instalar mysqldump"
fi
