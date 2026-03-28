#!/usr/bin/env bash
# ╔═══════════════════════════════════════════════════════════════╗
# ║  LATENCY WATCH - Monitor contínuo de latência Docker/WSL2    ║
# ║  Captura spikes e registra o estado do sistema naquele momento║
# ╚═══════════════════════════════════════════════════════════════╝
#
# Uso:
#   ./latency-watch.sh                        # monitora porta 8080
#   ./latency-watch.sh 8080 8081 8082         # monitora múltiplas portas
#   THRESHOLD=100 ./latency-watch.sh          # alerta acima de 100ms
#
# O log é salvo em ./monitor-logs/latency-YYYY-MM-DD.log

set -u

# === CONFIGURAÇÃO ===
THRESHOLD_MS="${THRESHOLD:-100}"          # ms acima disso = SPIKE
INTERVAL="${INTERVAL:-3}"                 # segundos entre checks
LOG_DIR="${LOG_DIR:-$(dirname "$0")/monitor-logs}"
ENDPOINT="${ENDPOINT:-/validaToken}"      # rota pra testar

# Cores
if [ -t 1 ]; then
  RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
  CYAN='\033[0;36m'; NC='\033[0m'; BOLD='\033[1m'
else
  RED=''; GREEN=''; YELLOW=''; CYAN=''; NC=''; BOLD=''
fi

# Portas a monitorar (argumentos ou default 8080)
if [ $# -gt 0 ]; then
  PORTS=("$@")
else
  # Auto-detectar portas de containers api_mvc rodando
  mapfile -t PORTS < <(docker ps --filter "ancestor=api_mvc:latest" --format '{{.Ports}}' 2>/dev/null | grep -oP '\d+(?=->80/tcp)' | sort -u)
  if [ ${#PORTS[@]} -eq 0 ]; then
    PORTS=(8080)
  fi
fi

mkdir -p "$LOG_DIR"
LOG_FILE="$LOG_DIR/latency-$(date +%Y-%m-%d).log"

spike_count=0
total_checks=0
max_latency=0

log_spike() {
  local port=$1 latency=$2 timestamp=$3
  spike_count=$((spike_count + 1))
  
  # Captura estado do sistema no momento do spike
  local mem_info swap_info cpu_load docker_stats
  mem_info=$(free -m | awk 'NR==2{printf "%dMB/%dMB (%.0f%%)", $3, $2, $3/$2*100}')
  swap_info=$(free -m | awk 'NR==3{printf "%dMB/%dMB", $3, $2}')
  cpu_load=$(cat /proc/loadavg | cut -d' ' -f1-3)
  
  # Top 5 processos por memória
  local top_procs
  top_procs=$(ps aux --sort=-%mem | head -6 | tail -5 | awk '{printf "  %s %.0fMB %s\n", $1, $6/1024, $11}')
  
  # Docker stats
  docker_stats=$(docker stats --no-stream --format "  {{.Name}}: CPU={{.CPUPerc}} MEM={{.MemUsage}}" 2>/dev/null)
  
  # I/O wait
  local iowait
  iowait=$(vmstat 1 2 | tail -1 | awk '{print $16}')
  
  cat >> "$LOG_FILE" <<EOF

===== SPIKE #${spike_count} ====================================
Timestamp: ${timestamp}
Port: ${port}
Latency: ${latency}ms (threshold: ${THRESHOLD_MS}ms)
---------- System State ----------
Memory: ${mem_info}
Swap: ${swap_info}
Load: ${cpu_load}
I/O Wait: ${iowait}%
---------- Top Processes ----------
${top_procs}
---------- Docker Containers ----------
${docker_stats}
==================================================

EOF

  printf "${RED}${BOLD}⚡ SPIKE${NC} port:${port} ${RED}${latency}ms${NC} | mem:${mem_info} swap:${swap_info} load:${cpu_load} iowait:${iowait}%%\n"
}

# Header
printf "${BOLD}╔═══════════════════════════════════════════╗${NC}\n"
printf "${BOLD}║   LATENCY WATCH - Monitor de Spikes       ║${NC}\n"
printf "${BOLD}╚═══════════════════════════════════════════╝${NC}\n"
printf "${CYAN}Portas:${NC}     %s\n" "${PORTS[*]}"
printf "${CYAN}Threshold:${NC} ${THRESHOLD_MS}ms\n"
printf "${CYAN}Intervalo:${NC} ${INTERVAL}s\n"
printf "${CYAN}Endpoint:${NC}  ${ENDPOINT}\n"
printf "${CYAN}Log:${NC}       ${LOG_FILE}\n"
printf "${CYAN}Ctrl+C para parar${NC}\n\n"

echo "=== Latency Watch started at $(date) ===" >> "$LOG_FILE"
echo "Ports: ${PORTS[*]} | Threshold: ${THRESHOLD_MS}ms | Interval: ${INTERVAL}s" >> "$LOG_FILE"

cleanup() {
  echo ""
  printf "${BOLD}=== Resumo ===${NC}\n"
  printf "Total checks: %d | Spikes: %d | Max latency: %dms\n" "$total_checks" "$spike_count" "$max_latency"
  echo "=== Watch stopped at $(date) | Checks: ${total_checks} | Spikes: ${spike_count} | Max: ${max_latency}ms ===" >> "$LOG_FILE"
  exit 0
}
trap cleanup INT TERM

while true; do
  timestamp=$(date '+%Y-%m-%d %H:%M:%S')
  line="${timestamp}"
  any_spike=false
  
  for port in "${PORTS[@]}"; do
    # Mede latência com curl (tempo total em ms)
    latency=$(curl -s -o /dev/null -w '%{time_total}' --connect-timeout 2 --max-time 5 "http://localhost:${port}${ENDPOINT}" 2>/dev/null)
    
    if [ $? -ne 0 ]; then
      line="${line} | :${port}=TIMEOUT"
      printf "${YELLOW}[%s]${NC} :${port} ${RED}TIMEOUT${NC}\n" "$timestamp"
      echo "${timestamp} | port:${port} | TIMEOUT" >> "$LOG_FILE"
      continue
    fi
    
    # Converter para ms (curl retorna em segundos com decimais)
    latency_ms=$(echo "$latency" | awk '{printf "%.0f", $1 * 1000}')
    total_checks=$((total_checks + 1))
    
    # Atualizar máximo
    if [ "$latency_ms" -gt "$max_latency" ]; then
      max_latency=$latency_ms
    fi
    
    if [ "$latency_ms" -gt "$THRESHOLD_MS" ]; then
      log_spike "$port" "$latency_ms" "$timestamp"
      any_spike=true
    else
      # Normal - mostra em verde, compacto
      line="${line} | :${port}=${latency_ms}ms"
    fi
  done
  
  if [ "$any_spike" = false ]; then
    # Linha compacta para operação normal
    printf "${GREEN}[%s]${NC}%s\n" "$timestamp" "$(echo "$line" | sed "s/$timestamp//")"
  fi
  
  sleep "$INTERVAL"
done
