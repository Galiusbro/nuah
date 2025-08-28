#!/bin/bash

echo "=== Проверка статуса валидатора ==="

# Проверяем, что валидатор запущен
if ! pgrep -f "solana-validator" > /dev/null; then
    echo "❌ Валидатор не запущен"
    exit 1
fi

echo "✅ Валидатор запущен"

# Проверяем RPC
echo -n "RPC (порт 8899): "
if curl -s -X POST -H "Content-Type: application/json" -d '{"jsonrpc":"2.0","id":1,"method":"getSlot"}' http://localhost:8899 > /dev/null 2>&1; then
    echo "✅ Работает"
else
    echo "❌ Не отвечает"
fi

# Проверяем gossip порт
echo -n "Gossip (порт 8001): "
if netstat -an | grep ":8001" | grep "LISTEN" > /dev/null; then
    echo "✅ Работает"
else
    echo "❌ Не слушает"
fi

# Получаем текущий слот
echo -n "Текущий слот: "
SLOT=$(curl -s -X POST -H "Content-Type: application/json" -d '{"jsonrpc":"2.0","id":1,"method":"getSlot"}' http://localhost:8899 | grep -o '"result":[0-9]*' | cut -d: -f2)
if [ -n "$SLOT" ]; then
    echo "✅ $SLOT"
else
    echo "❌ Не удалось получить"
fi

# Получаем genesis hash
echo -n "Genesis hash: "
GENESIS_HASH=$(./target/release/solana-ledger-tool genesis-hash --ledger test-ledger 2>/dev/null | tail -1)
if [ -n "$GENESIS_HASH" ]; then
    echo "✅ $GENESIS_HASH"
else
    echo "❌ Не удалось получить"
fi

echo ""
echo "=== Команды для управления ==="
echo "Запуск валидатора: ./start-validator.sh"
echo "Остановка: pkill -f solana-validator"
echo "Логи: tail -f /tmp/solana-validator.log (если запущен с --log файл)"
echo "RPC URL: http://localhost:8899"
echo "WebSocket: ws://localhost:8900"
