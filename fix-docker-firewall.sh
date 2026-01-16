#!/bin/bash
# Fix Docker firewall rules to allow container-to-container communication

echo "Adicionando regras de firewall para permitir comunicação entre containers Docker..."

# Permitir tráfego nas interfaces bridge do Docker
sudo iptables -C DOCKER-USER -i br+ -j ACCEPT 2>/dev/null || sudo iptables -I DOCKER-USER -i br+ -j ACCEPT
sudo iptables -C DOCKER-USER -o br+ -j ACCEPT 2>/dev/null || sudo iptables -I DOCKER-USER -o br+ -j ACCEPT

echo "Regras de firewall configuradas com sucesso!"
echo "Os containers Docker agora podem se comunicar entre si."
