#!/usr/bin/env bash

set -u

if [ -n "${NO_COLOR:-}" ] || [ ! -t 1 ]; then
  RED=''
  GREEN=''
  YELLOW=''
  CYAN=''
  NC=''
else
  RED='\033[0;31m'
  GREEN='\033[0;32m'
  YELLOW='\033[1;33m'
  CYAN='\033[0;36m'
  NC='\033[0m'
fi

FIX_MODE=false
FAILURES=0
WARNINGS=0
MYSQL_NEEDS_RECREATE=false

declare -a API_OVERRIDE=()
declare -a API_CONTAINERS=()
declare -a NEEDS_RECREATE=()

usage() {
  cat <<'EOF'
Usage: ./doctor.sh [--fix] [--api-container NAME]...

Checks local Docker Infra stability for WSL/Docker Desktop:
- bind mounts and empty mounts
- MySQL tuning effectively loaded
- internal DNS and DB latency
- CPU throttling and OOM events

Options:
  --fix                    Recreate only containers detected as inconsistent.
  --api-container NAME     Check only a specific API container (repeatable).
  -h, --help               Show this help.
EOF
}

log_info() { printf "${CYAN}[info]${NC} %s\n" "$*"; }
log_ok() { printf "${GREEN}[ok]${NC} %s\n" "$*"; }
log_warn() { printf "${YELLOW}[warn]${NC} %s\n" "$*"; WARNINGS=$((WARNINGS + 1)); }
log_fail() { printf "${RED}[fail]${NC} %s\n" "$*"; FAILURES=$((FAILURES + 1)); }

contains_value() {
  local needle="$1"
  shift
  local item
  for item in "$@"; do
    if [ "$item" = "$needle" ]; then
      return 0
    fi
  done
  return 1
}

add_recreate_target() {
  local container="$1"
  if ! contains_value "$container" "${NEEDS_RECREATE[@]}"; then
    NEEDS_RECREATE+=("$container")
  fi
}

require_docker() {
  if ! command -v docker >/dev/null 2>&1; then
    log_fail "docker command not found."
    return 1
  fi
  if ! docker info >/dev/null 2>&1; then
    log_fail "Docker daemon is not reachable."
    return 1
  fi
  return 0
}

is_running_container() {
  local container="$1"
  docker ps --format '{{.Names}}' | grep -qx "$container"
}

get_mount_fstype() {
  local container="$1"
  local target="$2"
  docker exec "$container" sh -lc "awk -v t='$target' '\$5==t{split(\$0,a,\" - \"); split(a[2],b,\" \"); print b[1]; exit}' /proc/self/mountinfo" 2>/dev/null
}

container_env_value() {
  local container="$1"
  local key="$2"
  docker inspect "$container" --format '{{range .Config.Env}}{{println .}}{{end}}' \
    | sed -n "s/^${key}=//p" \
    | head -n1
}

discover_api_containers() {
  API_CONTAINERS=()

  if [ "${#API_OVERRIDE[@]}" -gt 0 ]; then
    local c
    for c in "${API_OVERRIDE[@]}"; do
      if is_running_container "$c"; then
        API_CONTAINERS+=("$c")
      else
        log_fail "API container '$c' is not running."
      fi
    done
    return
  fi

  if ! docker network inspect shared_network >/dev/null 2>&1; then
    log_fail "Docker network 'shared_network' was not found."
    return
  fi

  mapfile -t API_CONTAINERS < <(
    docker network inspect shared_network --format '{{range $id, $c := .Containers}}{{println $c.Name}}{{end}}' \
      | sed '/^$/d' \
      | grep -vE '^(mysql_shared|phpmyadmin_shared|infra_doctor_monitor)$' || true
  )

  if [ "${#API_CONTAINERS[@]}" -eq 0 ]; then
    log_warn "No API container found in 'shared_network'."
  else
    log_info "API containers detected: ${API_CONTAINERS[*]}"
  fi
}

check_api_mounts() {
  local container="$1"
  local fs_type
  local top_entries

  if ! is_running_container "$container"; then
    log_fail "Container '$container' is not running."
    add_recreate_target "$container"
    return
  fi

  fs_type="$(get_mount_fstype "$container" "/var/www/html")"
  if [ -z "$fs_type" ]; then
    log_fail "$container: /var/www/html mount not found."
    add_recreate_target "$container"
    return
  elif [ "$fs_type" = "tmpfs" ]; then
    log_fail "$container: /var/www/html mounted as tmpfs (expected ext4 bind mount)."
    add_recreate_target "$container"
    return
  else
    log_ok "$container: /var/www/html mount filesystem = $fs_type."
  fi

  top_entries="$(docker exec "$container" sh -lc "find /var/www/html -mindepth 1 -maxdepth 1 2>/dev/null | wc -l" 2>/dev/null | tr -d '[:space:]')"
  if [ -z "$top_entries" ]; then
    log_fail "$container: unable to read /var/www/html entries."
    add_recreate_target "$container"
    return
  fi

  if [ "$top_entries" -le 1 ] && docker exec "$container" sh -lc "[ -d /var/www/html/vendor ]" >/dev/null 2>&1; then
    log_fail "$container: /var/www/html appears incomplete (only vendor present)."
    add_recreate_target "$container"
  else
    log_ok "$container: /var/www/html has $top_entries top-level entries."
  fi
}

check_mysql_mounts() {
  local fs_conf
  local fs_init

  if ! is_running_container "mysql_shared"; then
    log_fail "Container 'mysql_shared' is not running."
    MYSQL_NEEDS_RECREATE=true
    return
  fi

  fs_conf="$(get_mount_fstype mysql_shared "/etc/mysql/conf.d")"
  fs_init="$(get_mount_fstype mysql_shared "/docker-entrypoint-initdb.d")"

  if [ "$fs_conf" = "tmpfs" ] || [ -z "$fs_conf" ]; then
    log_fail "mysql_shared: /etc/mysql/conf.d is '$fs_conf' (expected ext4 bind mount)."
    MYSQL_NEEDS_RECREATE=true
  else
    log_ok "mysql_shared: /etc/mysql/conf.d mount filesystem = $fs_conf."
  fi

  if [ "$fs_init" = "tmpfs" ] || [ -z "$fs_init" ]; then
    log_fail "mysql_shared: /docker-entrypoint-initdb.d is '$fs_init' (expected ext4 bind mount)."
    MYSQL_NEEDS_RECREATE=true
  else
    log_ok "mysql_shared: /docker-entrypoint-initdb.d mount filesystem = $fs_init."
  fi

  if docker exec mysql_shared sh -lc "[ -f /etc/mysql/conf.d/99-dev-performance.cnf ]" >/dev/null 2>&1; then
    log_ok "mysql_shared: 99-dev-performance.cnf is present."
  else
    log_fail "mysql_shared: 99-dev-performance.cnf is missing inside container."
    MYSQL_NEEDS_RECREATE=true
  fi
}

check_mysql_tuning() {
  local query_output
  local -A expected
  local -A actual
  local key
  local expected_val
  local actual_val

  expected=(
    [innodb_flush_log_at_trx_commit]=2
    [sync_binlog]=0
    [log_bin]=OFF
    [table_open_cache]=1024
    [tmp_table_size]=67108864
    [max_heap_table_size]=67108864
    [innodb_buffer_pool_size]=268435456
    [max_connections]=120
    [performance_schema]=OFF
  )

  if ! query_output="$(docker exec mysql_shared sh -lc "mysql -N -uroot -proot -e \"SHOW VARIABLES WHERE Variable_name IN ('innodb_flush_log_at_trx_commit','sync_binlog','log_bin','table_open_cache','tmp_table_size','max_heap_table_size','innodb_buffer_pool_size','max_connections','performance_schema');\"" 2>/dev/null)"; then
    log_fail "mysql_shared: unable to read MySQL runtime variables."
    MYSQL_NEEDS_RECREATE=true
    return
  fi

  while IFS=$'\t' read -r key actual_val; do
    [ -n "$key" ] && actual["$key"]="$actual_val"
  done <<<"$query_output"

  for key in "${!expected[@]}"; do
    expected_val="${expected[$key]}"
    actual_val="${actual[$key]:-MISSING}"

    if [ "$key" = "log_bin" ] || [ "$key" = "performance_schema" ]; then
      expected_val="$(printf '%s' "$expected_val" | tr '[:lower:]' '[:upper:]')"
      actual_val="$(printf '%s' "$actual_val" | tr '[:lower:]' '[:upper:]')"
    fi

    if [ "$actual_val" != "$expected_val" ]; then
      log_fail "mysql_shared: $key=$actual_val (expected $expected_val)."
      MYSQL_NEEDS_RECREATE=true
    else
      log_ok "mysql_shared: $key=$actual_val."
    fi
  done
}

check_resource_signals() {
  local container
  local cpu_stat
  local mem_events
  local throttled
  local oom_kill

  for container in mysql_shared "${API_CONTAINERS[@]}"; do
    if ! is_running_container "$container"; then
      continue
    fi

    cpu_stat="$(docker exec "$container" sh -lc "cat /sys/fs/cgroup/cpu.stat 2>/dev/null" 2>/dev/null || true)"
    mem_events="$(docker exec "$container" sh -lc "cat /sys/fs/cgroup/memory.events 2>/dev/null" 2>/dev/null || true)"

    throttled="$(printf '%s\n' "$cpu_stat" | awk '/nr_throttled/{print $2; exit}')"
    oom_kill="$(printf '%s\n' "$mem_events" | awk '/oom_kill/{print $2; exit}')"

    throttled="${throttled:-0}"
    oom_kill="${oom_kill:-0}"

    if [ "$throttled" -gt 0 ] 2>/dev/null; then
      log_warn "$container: CPU throttling events detected (nr_throttled=$throttled)."
    else
      log_ok "$container: no CPU throttling detected."
    fi

    if [ "$oom_kill" -gt 0 ] 2>/dev/null; then
      log_fail "$container: OOM kill events detected (oom_kill=$oom_kill)."
      add_recreate_target "$container"
    else
      log_ok "$container: no OOM kill detected."
    fi
  done
}

check_dns_and_latency() {
  local container
  local db_host
  local db_port
  local db_name
  local db_user
  local db_pass
  local latency_output
  local max_ms
  local avg_ms

  for container in "${API_CONTAINERS[@]}"; do
    if ! is_running_container "$container"; then
      continue
    fi

    if docker exec "$container" sh -lc "getent hosts mysql_shared >/dev/null" >/dev/null 2>&1; then
      log_ok "$container: DNS resolution for mysql_shared is working."
    else
      log_fail "$container: cannot resolve mysql_shared with getent."
      add_recreate_target "$container"
      continue
    fi

    if ! docker exec "$container" sh -lc "command -v php >/dev/null" >/dev/null 2>&1; then
      log_warn "$container: php binary not found; skipping DB latency test."
      continue
    fi

    db_host="$(container_env_value "$container" "DB_HOST")"
    db_port="$(container_env_value "$container" "DB_PORT")"
    db_name="$(container_env_value "$container" "DB_NAME")"
    db_user="$(container_env_value "$container" "DB_USER")"
    db_pass="$(container_env_value "$container" "DB_PASS")"

    db_host="${db_host:-mysql_shared}"
    db_port="${db_port:-3306}"
    db_user="${db_user:-root}"
    db_pass="${db_pass:-root}"

    if [ -z "$db_name" ]; then
      log_warn "$container: DB_NAME not set; skipping DB latency test."
      continue
    fi

    latency_output="$(
      docker exec \
        -e DOCTOR_DB_HOST="$db_host" \
        -e DOCTOR_DB_PORT="$db_port" \
        -e DOCTOR_DB_NAME="$db_name" \
        -e DOCTOR_DB_USER="$db_user" \
        -e DOCTOR_DB_PASS="$db_pass" \
        "$container" \
        php -r '
          $host = getenv("DOCTOR_DB_HOST");
          $port = getenv("DOCTOR_DB_PORT");
          $db   = getenv("DOCTOR_DB_NAME");
          $user = getenv("DOCTOR_DB_USER");
          $pass = getenv("DOCTOR_DB_PASS");
          $dsn  = "mysql:host={$host};port={$port};dbname={$db}";
          for ($i = 0; $i < 6; $i++) {
            $start = microtime(true);
            $pdo = new PDO($dsn, $user, $pass, [PDO::ATTR_TIMEOUT => 2]);
            $pdo->query("SELECT 1")->fetch();
            echo number_format((microtime(true) - $start) * 1000, 2) . PHP_EOL;
          }
        ' 2>/dev/null
    )"

    if [ -z "$latency_output" ]; then
      log_fail "$container: failed to run DB latency probe."
      add_recreate_target "$container"
      continue
    fi

    max_ms="$(printf '%s\n' "$latency_output" | awk 'NF{if($1+0>m)m=$1+0} END{if(NR==0){print "0.00"}else{printf "%.2f", m}}')"
    avg_ms="$(printf '%s\n' "$latency_output" | awk 'NF{s+=$1; n++} END{if(n==0){print "0.00"}else{printf "%.2f", s/n}}')"

    if awk "BEGIN { exit !($max_ms > 25) }"; then
      log_warn "$container: DB latency high (avg=${avg_ms}ms, max=${max_ms}ms)."
    else
      log_ok "$container: DB latency stable (avg=${avg_ms}ms, max=${max_ms}ms)."
    fi
  done
}

compose_recreate_for_container() {
  local container="$1"
  local cfg_files
  local cfg_file
  local workdir
  local service

  cfg_files="$(docker inspect "$container" --format '{{ index .Config.Labels "com.docker.compose.project.config_files" }}' 2>/dev/null || true)"
  workdir="$(docker inspect "$container" --format '{{ index .Config.Labels "com.docker.compose.project.working_dir" }}' 2>/dev/null || true)"
  service="$(docker inspect "$container" --format '{{ index .Config.Labels "com.docker.compose.service" }}' 2>/dev/null || true)"

  cfg_file="${cfg_files%%,*}"

  if [ -z "$cfg_file" ] || [ -z "$workdir" ] || [ -z "$service" ]; then
    log_fail "Could not resolve compose metadata for '$container'."
    return 1
  fi

  if (cd "$workdir" && docker compose -f "$cfg_file" up -d --no-deps --force-recreate "$service"); then
    log_ok "$container: recreated via docker compose."
  else
    log_fail "$container: recreate failed."
    return 1
  fi

  if [ "$container" = "mysql_shared" ]; then
    local attempts=0
    while [ "$attempts" -lt 30 ]; do
      if docker exec mysql_shared mysqladmin ping -uroot -proot >/dev/null 2>&1; then
        log_ok "mysql_shared: ready after recreate."
        return 0
      fi
      attempts=$((attempts + 1))
      sleep 1
    done
    log_fail "mysql_shared did not become ready after recreate."
    return 1
  fi

  sleep 2
  return 0
}

run_fix() {
  local targets=("${NEEDS_RECREATE[@]}")
  local target

  if [ "$MYSQL_NEEDS_RECREATE" = true ] && ! contains_value "mysql_shared" "${targets[@]}"; then
    targets+=("mysql_shared")
  fi

  if [ "${#targets[@]}" -eq 0 ]; then
    log_info "No container flagged for recreate."
    return 0
  fi

  log_info "Fix mode enabled. Recreating: ${targets[*]}"
  for target in "${targets[@]}"; do
    compose_recreate_for_container "$target"
  done
}

run_checks() {
  FAILURES=0
  WARNINGS=0
  MYSQL_NEEDS_RECREATE=false
  NEEDS_RECREATE=()

  log_info "Checking Docker runtime..."
  require_docker || return 1

  check_mysql_mounts
  check_mysql_tuning

  discover_api_containers

  local api
  for api in "${API_CONTAINERS[@]}"; do
    check_api_mounts "$api"
  done

  check_dns_and_latency
  check_resource_signals

  return 0
}

main() {
  while [ "$#" -gt 0 ]; do
    case "$1" in
      --fix)
        FIX_MODE=true
        shift
        ;;
      --api-container)
        if [ "$#" -lt 2 ]; then
          log_fail "--api-container requires a value."
          exit 1
        fi
        API_OVERRIDE+=("$2")
        shift 2
        ;;
      -h|--help)
        usage
        exit 0
        ;;
      *)
        log_fail "Unknown argument: $1"
        usage
        exit 1
        ;;
    esac
  done

  run_checks

  if [ "$FIX_MODE" = true ]; then
    run_fix
    log_info "Re-running checks after fix..."
    run_checks
  fi

  printf "\n"
  log_info "Summary: failures=$FAILURES warnings=$WARNINGS"

  if [ "$FAILURES" -gt 0 ]; then
    log_info "Recommended action:"
    log_info "1) ./doctor.sh --fix"
    log_info "2) If still inconsistent, run: docker desktop restart && wsl --shutdown"
    exit 1
  fi

  exit 0
}

main "$@"
