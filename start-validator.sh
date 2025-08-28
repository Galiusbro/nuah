#!/bin/bash
set -e

echo "Запуск полноценного валидатора..."

# Проверяем наличие genesis блока
if [ ! -f "test-ledger/genesis.bin" ]; then
    echo "Ошибка: Genesis блок не найден!"
    echo "Сначала создайте genesis блок командой:"
    echo "./target/release/solana-genesis --cluster-type development --bootstrap-validator 4HsF1TZVyGRrgbHb1VqG7jTSggJfuKZUBczzAhhXcgNr CdouXV7MkywK3PrCj8eZBTxXG9NvzMCgNnaqGURvmJyX 8Hxncg3ZZ69xhVTnwb3CfTCdHk5KDAra37wszXWya69J --ledger test-ledger --hashes-per-tick auto --bootstrap-validator-lamports 500000000000000 --faucet-pubkey validator-keypair.json --faucet-lamports 1000000000000000"
    exit 1
fi

# Проверяем наличие ключей
if [ ! -f "validator-keypair.json" ] || [ ! -f "vote-account-keypair.json" ] || [ ! -f "stake-account-keypair.json" ]; then
    echo "Ошибка: Не все необходимые ключи найдены!"
    exit 1
fi

echo "Genesis hash: $(./target/release/solana-ledger-tool genesis-hash --ledger test-ledger)"
echo "Запускаем валидатор..."

# Запускаем валидатор
exec ./target/release/solana-validator \
    --identity validator-keypair.json \
    --vote-account vote-account-keypair.json \
    --ledger test-ledger \
    --rpc-port 8899 \
    --rpc-bind-address 0.0.0.0 \
    --gossip-port 8001 \
    --gossip-host 127.0.0.1 \
    --dynamic-port-range 8002-8020 \
    --expected-genesis-hash $(./target/release/solana-ledger-tool genesis-hash --ledger test-ledger) \
    --wal-recovery-mode skip_any_corrupted_record \
    --limit-ledger-size 50000000 \
    --enable-rpc-transaction-history \
    --full-rpc-api \
    --no-voting \
    --rpc-faucet-address 0.0.0.0:9900 \
    --log -
