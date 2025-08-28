#!/bin/bash
./target/release/solana-genesis \
  --bootstrap-validator $(./target/release/solana-keygen pubkey validator-keypair.json) $(./target/release/solana-keygen pubkey vote-account-keypair.json) $(./target/release/solana-keygen pubkey stake-account-keypair.json) \
  --ledger ./ledger \
  --hashes-per-tick sleep \
  --faucet-pubkey $(./target/release/solana-keygen pubkey validator-keypair.json) \
  --faucet-lamports 1000000000000000 \
  --bootstrap-stake-authorized-pubkey $(./target/release/solana-keygen pubkey validator-keypair.json)
