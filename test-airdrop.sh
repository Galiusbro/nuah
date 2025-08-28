#!/bin/bash

echo "🧪 Тестирование аирдропа с тестовым валидатором"

# Останавливаем production валидатор
echo "Останавливаем production валидатор..."
./validator-manager.sh stop

# Запускаем тестовый валидатор
echo "Запускаем тестовый валидатор..."
./target/release/solana-test-validator --reset --quiet &
TEST_VALIDATOR_PID=$!

# Ждем запуска тестового валидатора
echo "Ждем запуска тестового валидатора..."
sleep 10

# Создаем новый кошелек
echo "Создаем новый тестовый кошелек..."
./target/release/solana-keygen new --outfile test-airdrop-wallet.json --no-bip39-passphrase

# Получаем публичный ключ
WALLET_PUBKEY=$(./target/release/solana-keygen pubkey test-airdrop-wallet.json)
echo "Публичный ключ кошелька: $WALLET_PUBKEY"

# Проверяем баланс (должен быть 0)
echo "Проверяем начальный баланс..."
INITIAL_BALANCE=$(./target/release/solana balance $WALLET_PUBKEY --url http://localhost:8899)
echo "Начальный баланс: $INITIAL_BALANCE"

# Делаем аирдроп
echo "Делаем аирдроп 10 SOL..."
./target/release/solana airdrop 10 $WALLET_PUBKEY --url http://localhost:8899

# Проверяем баланс после аирдропа
echo "Проверяем баланс после аирдропа..."
FINAL_BALANCE=$(./target/release/solana balance $WALLET_PUBKEY --url http://localhost:8899)
echo "Финальный баланс: $FINAL_BALANCE"

# Делаем перевод между кошельками
echo "Создаем второй кошелек для теста перевода..."
./target/release/solana-keygen new --outfile test-airdrop-wallet2.json --no-bip39-passphrase
WALLET2_PUBKEY=$(./target/release/solana-keygen pubkey test-airdrop-wallet2.json)

echo "Делаем перевод 1 SOL со второго кошелька..."
./target/release/solana transfer $WALLET2_PUBKEY 1 --from test-airdrop-wallet.json --url http://localhost:8899 --allow-unfunded-recipient

# Проверяем балансы после перевода
echo "Балансы после перевода:"
echo "Кошелек 1: $(./target/release/solana balance $WALLET_PUBKEY --url http://localhost:8899)"
echo "Кошелек 2: $(./target/release/solana balance $WALLET2_PUBKEY --url http://localhost:8899)"

# Останавливаем тестовый валидатор
echo "Останавливаем тестовый валидатор..."
kill $TEST_VALIDATOR_PID

# Очищаем временные файлы
rm -f test-airdrop-wallet.json test-airdrop-wallet2.json

echo "✅ Тестирование завершено!"
