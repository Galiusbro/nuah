# Solana Validator - Инструкция по запуску

## Обзор

Этот проект содержит настройки для запуска полноценного Solana валидатора в режиме разработки.

## Структура файлов

- `start-validator.sh` - Скрипт запуска валидатора
- `check-validator.sh` - Скрипт проверки статуса
- `validator.yaml` - Конфигурация клиента Solana
- `test-ledger/` - Директория с genesis блоком и ledger
- `*.json` - Ключи валидатора, vote account и stake account

## Быстрый старт

### 1. Запуск валидатора

```bash
./start-validator.sh
```

### 2. Проверка статуса

```bash
./check-validator.sh
```

### 3. Остановка валидатора

```bash
pkill -f solana-validator
```

## Детальная настройка

### Создание нового genesis блока

Если нужно пересоздать genesis блок:

```bash
# Удалить старый ledger
rm -rf test-ledger

# Создать новый genesis
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
```

### Создание новых ключей

Если нужно создать новые ключи:

```bash
./target/release/solana-keygen new --outfile validator-keypair.json --no-bip39-passphrase
./target/release/solana-keygen new --outfile vote-account-keypair.json --no-bip39-passphrase
./target/release/solana-keygen new --outfile stake-account-keypair.json --no-bip39-passphrase
```

## Конфигурация

### Параметры валидатора

- **RPC порт**: 8899
- **Gossip порт**: 8001
- **Динамические порты**: 8002-8020
- **Ledger**: test-ledger/
- **Genesis hash**: AMa5ThiiBz9p5ybhm9TXY6aDV9i5cXC6GVD8CzvHz3B1

### Клиентская конфигурация

Файл `validator.yaml` содержит настройки для подключения клиентов:

```yaml
json_rpc_url: "http://127.0.0.1:8899"
websocket_url: "ws://127.0.0.1:8900"
keypair_path: validator-keypair.json
commitment: confirmed
```

## Мониторинг

### Проверка логов

Валидатор выводит логи в stdout. Для сохранения в файл:

```bash
./start-validator.sh > validator.log 2>&1
```

### RPC команды

```bash
# Получить текущий слот
curl -X POST -H "Content-Type: application/json" \
  -d '{"jsonrpc":"2.0","id":1,"method":"getSlot"}' \
  http://localhost:8899

# Получить баланс
curl -X POST -H "Content-Type: application/json" \
  -d '{"jsonrpc":"2.0","id":1,"method":"getBalance","params":["4HsF1TZVyGRrgbHb1VqG7jTSggJfuKZUBczzAhhXcgNr"]}' \
  http://localhost:8899
```

## Устранение неполадок

### Проблема: "Port already in use"

```bash
# Проверить занятые порты
lsof -i :8899 -i :8001

# Остановить процессы
pkill -f solana-validator
```

### Проблема: "Genesis hash mismatch"

```bash
# Пересоздать genesis блок
rm -rf test-ledger
# Выполнить команду создания genesis
```

### Проблема: "Vote account not found"

```bash
# Создать vote account (если нужно)
./target/release/solana create-vote-account vote-account-keypair.json validator-keypair.json
```

## Производительность

### Рекомендуемые настройки

- **RAM**: Минимум 8GB, рекомендуется 16GB+
- **CPU**: 4+ ядра
- **Диск**: SSD с минимум 100GB свободного места
- **Сеть**: Стабильное интернет-соединение

### Оптимизация

```bash
# Увеличить лимит файловых дескрипторов
ulimit -n 65536

# Установить переменные окружения для производительности
export SOLANA_METRICS_CONFIG="host=https://metrics.solana.com:8086,db=mainnet-beta,u=mainnet-beta_write,p=password"
```

## Безопасность

- Храните ключи в безопасном месте
- Не передавайте приватные ключи
- Используйте firewall для ограничения доступа
- Регулярно обновляйте Solana

## Поддержка

При возникновении проблем:

1. Проверьте логи валидатора
2. Убедитесь в корректности genesis блока
3. Проверьте доступность портов
4. Убедитесь в достаточности ресурсов системы
