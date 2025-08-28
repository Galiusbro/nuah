#!/bin/bash

# Production Solana Validator Manager
# Управление production валидатором Solana

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# Цвета для вывода
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Функции для вывода
log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
log_warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

# Проверка наличия необходимых инструментов
check_tools() {
    local tools=("solana-keygen" "solana-genesis" "solana-validator" "solana-ledger-tool")
    for tool in "${tools[@]}"; do
        if ! command -v "./target/release/$tool" &> /dev/null; then
            log_error "Инструмент $tool не найден. Сначала выполните: cargo build --release"
            exit 1
        fi
    done
}

# Создание production genesis с правильными параметрами
create_production_genesis() {
    log_info "Создание production genesis блока..."
    
    local mint_keypair="mint.json"
    local validator_keypair="validator-keypair.json"
    local vote_keypair="vote-account-keypair.json"
    local stake_keypair="stake-account-keypair.json"
    local faucet_keypair="faucet-keypair.json"
    
    # Создаем ключи если их нет
    if [[ ! -f "$mint_keypair" ]]; then
        log_info "Создание mint ключа..."
        ./target/release/solana-keygen new -o "$mint_keypair" --no-bip39-passphrase
    fi
    
    if [[ ! -f "$faucet_keypair" ]]; then
        log_info "Создание faucet ключа..."
        ./target/release/solana-keygen new -o "$faucet_keypair" --no-bip39-passphrase
    fi
    
    # Создаем genesis с production параметрами
    ./target/release/solana-genesis \
        --ledger production-ledger \
        --bootstrap-validator $(./target/release/solana-keygen pubkey "$validator_keypair") $(./target/release/solana-keygen pubkey "$vote_keypair") $(./target/release/solana-keygen pubkey "$stake_keypair") \
        --faucet-pubkey $(./target/release/solana-keygen pubkey "$faucet_keypair") \
        --faucet-lamports 1000000000000000 \
        --bootstrap-stake-authorized-pubkey $(./target/release/solana-keygen pubkey "$validator_keypair")
    
    log_success "Production genesis создан в папке production-ledger"
    
    # Показываем genesis hash
    local genesis_hash=$(./target/release/solana-ledger-tool genesis-hash --ledger production-ledger)
    log_info "Genesis Hash: $genesis_hash"
    echo "$genesis_hash" > production-genesis-hash.txt
}

# Запуск production валидатора (один узел - и лидер, и валидатор)
start_production_validator() {
    log_info "Запуск production валидатора..."
    
    if [[ ! -d "production-ledger" ]]; then
        log_error "Production ledger не найден. Сначала создайте genesis: $0 create-genesis"
        exit 1
    fi
    
    local genesis_hash=$(cat production-genesis-hash.txt 2>/dev/null || ./target/release/solana-ledger-tool genesis-hash --ledger production-ledger)
    
    # Останавливаем предыдущий валидатор если запущен
    pkill -f "solana-validator" || true
    sleep 2
    
    # Запускаем production валидатор
    nohup ./target/release/solana-validator \
        --identity validator-keypair.json \
        --vote-account vote-account-keypair.json \
        --ledger production-ledger \
        --rpc-port 8899 \
        --rpc-bind-address 0.0.0.0 \
        --full-rpc-api \
        --enable-rpc-transaction-history \
        --gossip-port 8001 \
        --dynamic-port-range 8000-8020 \
        --no-wait-for-vote-to-start-leader \
        --log - > production-validator.log 2>&1 &
    
    local pid=$!
    echo "$pid" > production-validator.pid
    
    log_success "Production валидатор запущен с PID: $pid"
    log_info "Логи: tail -f production-validator.log"
    log_info "RPC: http://localhost:8899"
    log_info "Gossip: 127.0.0.1:8001"
}

# Запуск faucet (опционально)
start_faucet() {
    log_info "Запуск faucet..."
    
    if [[ ! -f "faucet-keypair.json" ]]; then
        log_error "Faucet ключ не найден. Сначала создайте genesis: $0 create-genesis"
        exit 1
    fi
    
    # Останавливаем предыдущий faucet если запущен
    pkill -f "solana-faucet" || true
    sleep 2
    
    # Запускаем faucet (версия 2.0.0 не поддерживает --port и --bind-address)
    nohup ./target/release/solana-faucet \
        --keypair faucet-keypair.json > faucet.log 2>&1 &
    
    local pid=$!
    echo "$pid" > faucet.pid
    
    log_success "Faucet запущен с PID: $pid на порту 9900"
}

# Остановка всех сервисов
stop_all() {
    log_info "Остановка всех сервисов..."
    
    pkill -f "solana-validator" || true
    pkill -f "solana-faucet" || true
    
    rm -f production-validator.pid faucet.pid
    
    log_success "Все сервисы остановлены"
}

# Показать статус
show_status() {
    echo "=== Production Validator Status ==="
    
    # Проверяем валидатор
    if [[ -f "production-validator.pid" ]]; then
        local pid=$(cat production-validator.pid)
        if ps -p "$pid" > /dev/null; then
            echo "✅ Валидатор: запущен (PID: $pid)"
        else
            echo "❌ Валидатор: не запущен (PID файл устарел)"
            rm -f production-validator.pid
        fi
    else
        echo "❌ Валидатор: не запущен"
    fi
    
    # Проверяем faucet
    if [[ -f "faucet.pid" ]]; then
        local pid=$(cat faucet.pid)
        if ps -p "$pid" > /dev/null; then
            echo "✅ Faucet: запущен (PID: $pid)"
        else
            echo "❌ Faucet: не запущен (PID файл устарел)"
            rm -f faucet.pid
        fi
    else
        echo "❌ Faucet: не запущен"
    fi
    
    # Проверяем RPC
    if curl -s http://localhost:8899 -X POST -H "Content-Type: application/json" -d '{"jsonrpc":"2.0","id":1,"method":"getHealth"}' > /dev/null 2>&1; then
        echo "✅ RPC: доступен (http://localhost:8899)"
    else
        echo "❌ RPC: недоступен"
    fi
    
    # Проверяем genesis
    if [[ -d "production-ledger" ]]; then
        local genesis_hash=$(./target/release/solana-ledger-tool genesis-hash --ledger production-ledger 2>/dev/null || echo "не удалось получить")
        echo "✅ Genesis: создан (Hash: $genesis_hash)"
    else
        echo "❌ Genesis: не создан"
    fi
}

# Показать логи
show_logs() {
    local service=${1:-validator}
    
    case "$service" in
        validator|v)
            if [[ -f "production-validator.log" ]]; then
                tail -f production-validator.log
            else
                log_error "Лог файл валидатора не найден"
            fi
            ;;
        faucet|f)
            if [[ -f "faucet.log" ]]; then
                tail -f faucet.log
            else
                log_error "Лог файл faucet не найден"
            fi
            ;;
        *)
            log_error "Неизвестный сервис: $service. Используйте: validator|faucet"
            ;;
    esac
}

# Очистка
clean() {
    log_warning "Очистка всех данных production валидатора..."
    
    stop_all
    rm -rf production-ledger
    rm -f production-genesis-hash.txt
    rm -f production-validator.log faucet.log
    
    log_success "Все данные очищены"
}

# Показать справку
show_help() {
    cat << EOF
Production Solana Validator Manager

Использование: $0 <команда>

Команды:
  create-genesis    Создать production genesis блок
  start             Запустить production валидатор
  start-faucet      Запустить faucet
  stop              Остановить все сервисы
  status            Показать статус всех сервисов
  logs [service]    Показать логи (validator|faucet)
  clean             Очистить все данные
  help              Показать эту справку

Примеры:
  $0 create-genesis    # Создать genesis
  $0 start             # Запустить валидатор
  $0 start-faucet      # Запустить faucet
  $0 status            # Проверить статус
  $0 logs validator    # Логи валидатора
  $0 logs faucet       # Логи faucet

Важные порты:
  - RPC: 8899 (TCP)
  - WebSocket: 8900 (TCP) 
  - Gossip: 8001 (UDP)
  - TPU: 8003 (UDP)
  - Динамический диапазон: 8000-8020 (UDP)
  - Faucet: 9900 (TCP)

Для внешнего доступа откройте эти порты в файрволе!
EOF
}

# Основная логика
case "${1:-help}" in
    create-genesis)
        check_tools
        create_production_genesis
        ;;
    start)
        check_tools
        start_production_validator
        ;;
    start-faucet)
        check_tools
        start_faucet
        ;;
    stop)
        stop_all
        ;;
    status)
        show_status
        ;;
    logs)
        show_logs "$2"
        ;;
    clean)
        clean
        ;;
    help|--help|-h)
        show_help
        ;;
    *)
        log_error "Неизвестная команда: $1"
        show_help
        exit 1
        ;;
esac
