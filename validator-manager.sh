#!/bin/bash

# Solana Validator Manager
# Универсальный скрипт для управления валидатором

set -e

VALIDATOR_PID_FILE="/tmp/solana-validator.pid"
LOG_FILE="/tmp/solana-validator.log"

show_help() {
    echo "Solana Validator Manager"
    echo ""
    echo "Использование: $0 [команда]"
    echo ""
    echo "Команды:"
    echo "  start     - Запустить валидатор"
    echo "  stop      - Остановить валидатор"
    echo "  restart   - Перезапустить валидатор"
    echo "  status    - Показать статус"
    echo "  logs      - Показать логи в реальном времени"
    echo "  clean     - Очистить ledger и пересоздать genesis"
    echo "  help      - Показать эту справку"
    echo ""
    echo "Примеры:"
    echo "  $0 start"
    echo "  $0 status"
    echo "  $0 logs"
}

check_dependencies() {
    if [ ! -f "./target/release/solana-validator" ]; then
        echo "❌ Ошибка: solana-validator не найден. Сначала соберите проект:"
        echo "   cargo build --release --bin solana-validator"
        exit 1
    fi
    
    if [ ! -f "./target/release/solana-genesis" ]; then
        echo "❌ Ошибка: solana-genesis не найден. Сначала соберите проект:"
        echo "   cargo build --release --bin solana-genesis"
        exit 1
    fi
}

is_running() {
    if [ -f "$VALIDATOR_PID_FILE" ]; then
        local pid=$(cat "$VALIDATOR_PID_FILE")
        if kill -0 "$pid" 2>/dev/null; then
            return 0
        else
            rm -f "$VALIDATOR_PID_FILE"
        fi
    fi
    return 1
}

start_validator() {
    echo "🚀 Запуск валидатора..."
    
    if is_running; then
        echo "⚠️  Валидатор уже запущен (PID: $(cat $VALIDATOR_PID_FILE))"
        return 1
    fi
    
    # Проверяем наличие genesis блока
    if [ ! -f "test-ledger/genesis.bin" ]; then
        echo "❌ Genesis блок не найден. Создаю новый..."
        create_genesis
    fi
    
    # Запускаем валидатор в фоне
    nohup ./start-validator.sh > "$LOG_FILE" 2>&1 &
    local pid=$!
    
    # Сохраняем PID
    echo $pid > "$VALIDATOR_PID_FILE"
    
    echo "✅ Валидатор запущен (PID: $pid)"
    echo "📝 Логи: $LOG_FILE"
    echo "🌐 RPC: http://localhost:8899"
    
    # Ждем немного и проверяем статус
    sleep 3
    if is_running; then
        echo "✅ Валидатор успешно запущен и работает"
    else
        echo "❌ Ошибка запуска. Проверьте логи: $LOG_FILE"
        return 1
    fi
}

stop_validator() {
    echo "🛑 Остановка валидатора..."
    
    if ! is_running; then
        echo "⚠️  Валидатор не запущен"
        return 0
    fi
    
    local pid=$(cat "$VALIDATOR_PID_FILE")
    
    # Останавливаем валидатор
    if kill "$pid" 2>/dev/null; then
        echo "✅ Сигнал остановки отправлен (PID: $pid)"
        
        # Ждем завершения
        local count=0
        while kill -0 "$pid" 2>/dev/null && [ $count -lt 30 ]; do
            sleep 1
            count=$((count + 1))
            echo -n "."
        done
        echo ""
        
        if kill -0 "$pid" 2>/dev/null; then
            echo "⚠️  Принудительная остановка..."
            kill -9 "$pid" 2>/dev/null
        fi
        
        rm -f "$VALIDATOR_PID_FILE"
        echo "✅ Валидатор остановлен"
    else
        echo "❌ Ошибка остановки валидатора"
        return 1
    fi
}

restart_validator() {
    echo "🔄 Перезапуск валидатора..."
    stop_validator
    sleep 2
    start_validator
}

show_status() {
    echo "=== Статус валидатора ==="
    
    if is_running; then
        local pid=$(cat "$VALIDATOR_PID_FILE")
        echo "✅ Валидатор запущен (PID: $pid)"
        
        # Проверяем RPC
        echo -n "RPC (порт 8899): "
        if curl -s -X POST -H "Content-Type: application/json" \
           -d '{"jsonrpc":"2.0","id":1,"method":"getSlot"}' \
           http://localhost:8899 > /dev/null 2>&1; then
            echo "✅ Работает"
        else
            echo "❌ Не отвечает"
        fi
        
        # Получаем текущий слот
        echo -n "Текущий слот: "
        local slot=$(curl -s -X POST -H "Content-Type: application/json" \
                    -d '{"jsonrpc":"2.0","id":1,"method":"getSlot"}' \
                    http://localhost:8899 | grep -o '"result":[0-9]*' | cut -d: -f2)
        if [ -n "$slot" ]; then
            echo "✅ $slot"
        else
            echo "❌ Не удалось получить"
        fi
        
        # Проверяем размер лог файла
        if [ -f "$LOG_FILE" ]; then
            local size=$(du -h "$LOG_FILE" | cut -f1)
            echo "📝 Размер логов: $size"
        fi
        
    else
        echo "❌ Валидатор не запущен"
    fi
    
    # Проверяем genesis
    echo -n "Genesis блок: "
    if [ -f "test-ledger/genesis.bin" ]; then
        local genesis_hash=$(./target/release/solana-ledger-tool genesis-hash --ledger test-ledger 2>/dev/null | tail -1)
        if [ -n "$genesis_hash" ]; then
            echo "✅ $genesis_hash"
        else
            echo "❌ Ошибка чтения"
        fi
    else
        echo "❌ Не найден"
    fi
}

show_logs() {
    if [ ! -f "$LOG_FILE" ]; then
        echo "❌ Лог файл не найден. Запустите валидатор сначала."
        return 1
    fi
    
    echo "📝 Показываю логи валидатора (Ctrl+C для выхода)..."
    tail -f "$LOG_FILE"
}

create_genesis() {
    echo "🔧 Создание нового genesis блока..."
    
    # Удаляем старый ledger
    if [ -d "test-ledger" ]; then
        rm -rf test-ledger
        echo "🗑️  Старый ledger удален"
    fi
    
    # Создаем новый genesis
    ./target/release/solana-genesis \
        --cluster-type development \
        --bootstrap-validator 4HsF1TZVyGRrgbHb1VqG7jTSggJfuKZUBczzAhhXcgNr \
                              CdouXV7MkywK3PrCj8eZBTxXG9NvzMCgNnaqGURvmJyX \
                              8Hxncg3ZZ69xhVTnwb3CfTCdHk5KDAra37wszXWya69J \
        --ledger test-ledger \
        --hashes-per-tick auto \
        --bootstrap-validator-lamports 500000000000000 \
        --faucet-pubkey validator-keypair.json \
        --faucet-lamports 1000000000000000
    
    echo "✅ Genesis блок создан"
}

clean_ledger() {
    echo "🧹 Очистка ledger и пересоздание genesis..."
    
    if is_running; then
        echo "⚠️  Останавливаю валидатор перед очисткой..."
        stop_validator
    fi
    
    create_genesis
    echo "✅ Ledger очищен и genesis пересоздан"
}

# Основная логика
case "${1:-help}" in
    start)
        check_dependencies
        start_validator
        ;;
    stop)
        stop_validator
        ;;
    restart)
        check_dependencies
        restart_validator
        ;;
    status)
        show_status
        ;;
    logs)
        show_logs
        ;;
    clean)
        clean_ledger
        ;;
    help|--help|-h)
        show_help
        ;;
    *)
        echo "❌ Неизвестная команда: $1"
        echo ""
        show_help
        exit 1
        ;;
esac
