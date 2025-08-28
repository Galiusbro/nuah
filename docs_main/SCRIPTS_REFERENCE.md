# Scripts Reference

Complete reference for all available scripts and commands in the Solana validator setup.

## 📚 Scripts Overview

| Script | Purpose | Complexity | Usage |
|--------|---------|------------|-------|
| `start-production-validator.sh` | Production validator management | High | Full production setup |
| `start-test-validator.sh` | Test validator startup | Low | Quick development |
| `test-airdrop.sh` | Airdrop testing | Low | Testing functionality |
| `validator-manager.sh` | Legacy validator management | Medium | Basic operations |

## 🏭 Production Validator Script

### **Script: `start-production-validator.sh`**

**Purpose**: Complete production validator management system with genesis creation, validator startup, faucet management, and monitoring.

**Location**: Project root directory

**Prerequisites**: 
- `cargo build --release` completed
- Required binaries: `solana-keygen`, `solana-genesis`, `solana-validator`, `solana-ledger-tool`

### **Commands**

#### **`create-genesis`**
Creates a production genesis block with proper parameters.

```bash
./start-production-validator.sh create-genesis
```

**What it does:**
- Generates `mint.json` and `faucet-keypair.json` if they don't exist
- Creates `production-ledger/` directory with genesis data
- Sets proper genesis parameters for production use
- Saves genesis hash to `production-genesis-hash.txt`

**Output:**
```
[INFO] Создание production genesis блока...
[INFO] Создание mint ключа...
[INFO] Создание faucet ключа...
[SUCCESS] Production genesis создан в папке production-ledger
[INFO] Genesis Hash: 2kjg5X3SQdXdiSWT8UswwrgwpkYvceiWtwuiNAxHC11w
```

**Files created:**
- `production-ledger/` - Genesis and initial state
- `mint.json` - Mint authority keypair
- `faucet-keypair.json` - Faucet account keypair
- `production-genesis-hash.txt` - Genesis hash

#### **`start`**
Starts the production validator with optimized parameters.

```bash
./start-production-validator.sh start
```

**What it does:**
- Stops any existing validator processes
- Starts production validator with production-optimized flags
- Creates PID file for process management
- Redirects output to `production-validator.log`

**Key flags used:**
```bash
--no-wait-for-vote-to-start-leader  # Critical for single validator
--full-rpc-api                      # Enable all RPC methods
--enable-rpc-transaction-history    # Transaction history support
--dynamic-port-range 8000-8020     # Network port range
```

**Output:**
```
[INFO] Запуск production валидатора...
[SUCCESS] Production валидатор запущен с PID: 69077
[INFO] Логи: tail -f production-validator.log
[INFO] RPC: http://localhost:8899
[INFO] Gossip: 127.0.0.1:8001
```

#### **`start-faucet`**
Starts the faucet service for token distribution.

```bash
./start-production-validator.sh start-faucet
```

**What it does:**
- Stops any existing faucet processes
- Starts faucet service on port 9900
- Creates PID file for process management
- Redirects output to `faucet.log`

**Output:**
```
[INFO] Запуск faucet...
[SUCCESS] Faucet запущен с PID: 71887 на порту 9900
```

#### **`stop`**
Stops all validator and faucet services.

```bash
./start-production-validator.sh stop
```

**What it does:**
- Kills all `solana-validator` processes
- Kills all `solana-faucet` processes
- Removes PID files
- Cleans up process state

**Output:**
```
[INFO] Остановка всех сервисов...
[SUCCESS] Все сервисы остановлены
```

#### **`status`**
Shows the current status of all services.

```bash
./start-production-validator.sh status
```

**What it checks:**
- Validator process status
- Faucet process status
- RPC endpoint availability
- Genesis block status

**Output:**
```
=== Production Validator Status ===
✅ Валидатор: запущен (PID: 72883)
✅ Faucet: запущен (PID: 71887)
✅ RPC: доступен (http://localhost:8899)
✅ Genesis: создан (Hash: 2kjg5X3SQdXdiSWT8UswwrgwpkYvceiWtwuiNAxHC11w)
```

#### **`logs [service]`**
Shows real-time logs for specified service.

```bash
# Validator logs
./start-production-validator.sh logs validator

# Faucet logs
./start-production-validator.sh logs faucet

# Default (validator)
./start-production-validator.sh logs
```

**What it does:**
- Shows real-time logs using `tail -f`
- Supports `validator` and `faucet` services
- Defaults to validator if no service specified

**Output:**
```
# Real-time log stream
[2025-08-28T19:17:14.887242000Z INFO  solana_metrics::metrics] datapoint: ...
[2025-08-28T19:17:14.887263000Z INFO  solana_metrics::metrics] datapoint: ...
```

#### **`clean`**
Completely removes all production validator data.

```bash
./start-production-validator.sh clean
```

**What it does:**
- Stops all services
- Removes `production-ledger/` directory
- Removes genesis hash file
- Removes log files
- Removes PID files

**Output:**
```
[WARNING] Очистка всех данных production валидатора...
[SUCCESS] Все данные очищены
```

#### **`help`**
Shows comprehensive help information.

```bash
./start-production-validator.sh help
```

**Output:**
```
Production Solana Validator Manager

Использование: ./start-production-validator.sh <команда>

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
  ./start-production-validator.sh create-genesis    # Создать genesis
  ./start-production-validator.sh start             # Запустить валидатор
  ./start-production-validator.sh start-faucet      # Запустить faucet
  ./start-production-validator.sh status            # Проверить статус
  ./start-production-validator.sh logs validator    # Логи валидатора
  ./start-production-validator.sh logs faucet       # Логи faucet

Важные порты:
  - RPC: 8899 (TCP)
  - WebSocket: 8900 (TCP) 
  - Gossip: 8001 (UDP)
  - TPU: 8003 (UDP)
  - Динамический диапазон: 8000-8020 (UDP)
  - Faucet: 9900 (TCP)

Для внешнего доступа откройте эти порты в файрволе!
```

### **Configuration Files**

#### **Genesis Configuration**
The script creates genesis with these parameters:

```bash
./target/release/solana-genesis \
  --ledger production-ledger \
  --bootstrap-validator <VALIDATOR_PUBKEY> <VOTE_PUBKEY> <STAKE_PUBKEY> \
  --faucet-pubkey <FAUCET_PUBKEY> \
  --faucet-lamports 1000000000000000 \
  --bootstrap-stake-authorized-pubkey <VALIDATOR_PUBKEY>
```

#### **Validator Configuration**
The script starts validator with these flags:

```bash
--identity validator-keypair.json
--vote-account vote-account-keypair.json
--ledger production-ledger
--rpc-port 8899
--rpc-bind-address 0.0.0.0
--full-rpc-api
--enable-rpc-transaction-history
--gossip-port 8001
--dynamic-port-range 8000-8020
--expected-genesis-hash <HASH>
--no-wait-for-vote-to-start-leader
--log -
```

#### **Faucet Configuration**
The script starts faucet with these flags:

```bash
--keypair faucet-keypair.json
--port 9900
--bind-address 0.0.0.0
```

## 🧪 Test Validator Script

### **Script: `start-test-validator.sh`**

**Purpose**: Quick startup of test validator for development and testing.

**Location**: Project root directory

**Prerequisites**: `cargo build --release` completed

### **Usage**

```bash
./start-test-validator.sh
```

**What it does:**
- Starts `solana-test-validator` with optimized parameters
- Uses built-in faucet for token distribution
- Configures RPC and gossip ports
- Provides instant development environment

**Parameters used:**
```bash
--reset                    # Clear existing data
--quiet                    # Reduce log verbosity
--rpc-port 8899           # RPC endpoint
--gossip-port 8001        # Gossip network
--faucet-port 9900        # Faucet service
```

**Features:**
- ✅ **Instant startup** - no genesis creation needed
- ✅ **Built-in faucet** - automatic token distribution
- ✅ **Simple configuration** - minimal setup required
- ✅ **Development focused** - optimized for coding workflow

## 🧪 Test Airdrop Script

### **Script: `test-airdrop.sh`**

**Purpose**: Demonstrates and tests airdrop functionality with test validator.

**Location**: Project root directory

**Prerequisites**: `cargo build --release` completed

### **Usage**

```bash
./test-airdrop.sh
```

**What it does:**
- Stops any existing validators
- Starts test validator in background
- Creates test wallets
- Performs airdrop operations
- Tests token transfers
- Cleans up test data

**Test sequence:**
1. **Start test validator**
2. **Create test wallet 1**
3. **Airdrop 10 SOL to wallet 1**
4. **Create test wallet 2**
5. **Transfer 1 SOL from wallet 1 to wallet 2**
6. **Display final balances**
7. **Cleanup and stop validator**

**Output:**
```
🧪 Тестирование аирдропа с тестовым валидатором
Публичный ключ кошелька: 6oPEZaq3BhvfZY5okgzytyrxa5794beyDMYbBAinNYQz
Начальный баланс: 0 NUAH
Финальный баланс: 10 NUAH
Делаем перевод 1 SOL со второго кошелька...
Балансы после перевода:
Кошелек 1: 9 NUAH
Кошелек 2: 1 NUAH
✅ Тестирование завершено!
```

## 🔧 Legacy Validator Manager

### **Script: `validator-manager.sh`**

**Purpose**: Legacy validator management system (superseded by `start-production-validator.sh`).

**Location**: Project root directory

**Prerequisites**: `cargo build --release` completed

### **Commands**

#### **`start`**
Starts the legacy validator.

```bash
./validator-manager.sh start
```

#### **`stop`**
Stops the legacy validator.

```bash
./validator-manager.sh stop
```

#### **`restart`**
Restarts the legacy validator.

```bash
./validator-manager.sh restart
```

#### **`status`**
Shows legacy validator status.

```bash
./validator-manager.sh status
```

#### **`logs`**
Shows legacy validator logs.

```bash
./validator-manager.sh logs
```

#### **`clean`**
Cleans legacy validator data.

```bash
./validator-manager.sh clean
```

## 📁 File Structure

### **Generated Files**

| File | Purpose | Generated By | Location |
|------|---------|--------------|----------|
| `production-ledger/` | Genesis and ledger data | `create-genesis` | Project root |
| `mint.json` | Mint authority keypair | `create-genesis` | Project root |
| `faucet-keypair.json` | Faucet account keypair | `create-genesis` | Project root |
| `production-genesis-hash.txt` | Genesis hash | `create-genesis` | Project root |
| `production-validator.pid` | Validator process ID | `start` | Project root |
| `faucet.pid` | Faucet process ID | `start-faucet` | Project root |
| `production-validator.log` | Validator logs | `start` | Project root |
| `faucet.log` | Faucet logs | `start-faucet` | Project root |

### **Required Keypairs**

| Keypair | Purpose | Location | Generated By |
|----------|---------|----------|--------------|
| `validator-keypair.json` | Validator identity | Project root | Manual |
| `vote-account-keypair.json` | Vote account | Project root | Manual |
| `stake-account-keypair.json` | Stake account | Project root | Manual |

## 🔍 Troubleshooting

### **Common Script Issues**

#### **"Command not found"**
**Problem**: Script not executable
**Solution**: 
```bash
chmod +x start-production-validator.sh
```

#### **"Permission denied"**
**Problem**: Insufficient permissions
**Solution**: 
```bash
sudo chown $USER:$USER start-production-validator.sh
chmod +x start-production-validator.sh
```

#### **"PID file not found"**
**Problem**: Process management issue
**Solution**: 
```bash
./start-production-validator.sh clean
./start-production-validator.sh start
```

#### **"Port already in use"**
**Problem**: Port conflicts
**Solution**: 
```bash
sudo lsof -i :8899
sudo kill -9 <PID>
./start-production-validator.sh start
```

### **Debug Mode**

To enable debug output, modify scripts to add:

```bash
set -x  # Enable debug mode
```

Or run with bash debug:

```bash
bash -x start-production-validator.sh start
```

## 📊 Script Dependencies

### **Required Binaries**

| Binary | Purpose | Location |
|--------|---------|----------|
| `solana-keygen` | Key generation | `target/release/` |
| `solana-genesis` | Genesis creation | `target/release/` |
| `solana-validator` | Validator daemon | `target/release/` |
| `solana-ledger-tool` | Ledger operations | `target/release/` |
| `solana-faucet` | Faucet service | `target/release/` |

### **System Dependencies**

| Dependency | Purpose | Installation |
|------------|---------|--------------|
| `curl` | HTTP requests | `apt install curl` |
| `jq` | JSON processing | `apt install jq` |
| `ps` | Process management | Built-in |
| `netstat` | Network status | `apt install net-tools` |

## 🚀 Advanced Usage

### **Custom Genesis Parameters**

To customize genesis creation, modify the script:

```bash
# Edit start-production-validator.sh
./target/release/solana-genesis \
  --ledger production-ledger \
  --bootstrap-validator <VALIDATOR_PUBKEY> <VOTE_PUBKEY> <STAKE_PUBKEY> \
  --faucet-pubkey <FAUCET_PUBKEY> \
  --faucet-lamports 2000000000000000 \  # Custom faucet amount
  --bootstrap-stake-authorized-pubkey <VALIDATOR_PUBKEY>
```

### **Custom Validator Flags**

To add custom validator flags, modify the script:

```bash
# Edit start-production-validator.sh
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
  --expected-genesis-hash "$genesis_hash" \
  --no-wait-for-vote-to-start-leader \
  --limit-ledger-size 100000000 \  # Custom ledger size
  --log - > production-validator.log 2>&1 &
```

### **Multiple Validators**

To run multiple validators, create separate instances:

```bash
# Validator 1
./start-production-validator.sh start

# Validator 2 (different ports)
./start-production-validator.sh start --rpc-port 8900 --gossip-port 8002

# Validator 3 (different ports)
./start-production-validator.sh start --rpc-port 8901 --gossip-port 8003
```

## 📋 Best Practices

### **Script Usage**

1. **Always check status first**: `./start-production-validator.sh status`
2. **Use logs for debugging**: `./start-production-validator.sh logs validator`
3. **Clean before major changes**: `./start-production-validator.sh clean`
4. **Backup before operations**: Copy important files before major changes

### **Process Management**

1. **Use PID files**: Scripts create PID files for process management
2. **Graceful shutdown**: Use `stop` command instead of killing processes
3. **Monitor resources**: Check system resources during operation
4. **Log rotation**: Implement log rotation for long-running operations

### **Security**

1. **Secure keypairs**: Store keypairs securely, not in version control
2. **Limit access**: Restrict script access to authorized users
3. **Network security**: Configure firewalls and access controls
4. **Regular updates**: Keep scripts and dependencies updated

---

**🎯 Scripts are ready for production use!**

**Next**: Learn about [Validator Management](./VALIDATOR_MANAGEMENT.md) or explore [Production Guide](./PRODUCTION_GUIDE.md).
