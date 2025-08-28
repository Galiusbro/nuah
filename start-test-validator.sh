#!/bin/bash
./target/release/solana-test-validator \
  --ledger ./test-ledger \
  --rpc-port 8899 \
  --faucet-port 9901 \
  --faucet-sol 1000000 \
  --faucet-per-request-sol-cap 1000 \
  --faucet-per-time-sol-cap 10000 \
  --faucet-time-slice-secs 1 \
  --reset \
  --log
