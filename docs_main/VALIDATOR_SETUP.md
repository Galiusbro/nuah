# Validator Setup Guide

Complete guide for setting up Solana validators, from basic test validators to production-ready systems.

## 🎯 Overview

This guide covers two main validator types:

| Type | Purpose | Setup Time | Complexity |
|------|---------|------------|------------|
| **Test Validator** | Development & Testing | 2 minutes | Low |
| **Production Validator** | Production & Advanced Testing | 10 minutes | Medium |

## 🧪 Test Validator Setup

### **What is a Test Validator?**

A test validator (`solana-test-validator`) is a simplified, single-node validator designed for:
- 🚀 **Quick development setup**
- 🧪 **Program testing and debugging**
- 📚 **Learning Solana concepts**
- 🔬 **Prototyping and experimentation**

### **Advantages**
- ✅ **Instant startup** - no genesis creation needed
- ✅ **Built-in faucet** - automatic token distribution
- ✅ **Simple configuration** - minimal setup required
- ✅ **Development focused** - optimized for coding workflow

### **Limitations**
- ❌ **Single node** - no real consensus
- ❌ **Limited scalability** - not for production use
- ❌ **Simplified networking** - basic gossip only

### **Setup Steps**

#### **Step 1: Build the Project**
```bash
cargo build --release
```

#### **Step 2: Start the Validator**
```bash
# Simple start
./start-test-validator.sh

# Or with custom parameters
./target/release/solana-test-validator \
  --reset \
  --quiet \
  --rpc-port 8899 \
  --gossip-port 8001
```

#### **Step 3: Verify Operation**
```bash
# Check RPC health
curl -s http://localhost:8899 -X POST -H "Content-Type: application/json" \
  -d '{"jsonrpc":"2.0","id":1,"method":"getHealth"}' | jq .

# Check current slot
curl -s http://localhost:8899 -X POST -H "Content-Type: application/json" \
  -d '{"jsonrpc":"2.0","id":1,"method":"getSlot"}' | jq .
```

#### **Step 4: Test Basic Operations**
```bash
# Create test wallet
./target/release/solana-keygen new -o test-wallet.json --no-bip39-passphrase

# Get test tokens
./target/release/solana airdrop 10 $(./target/release/solana-keygen pubkey test-wallet.json)

# Check balance
./target/release/solana balance $(./target/release/solana-keygen pubkey test-wallet.json)
```

## 🏭 Production Validator Setup

### **What is a Production Validator?**

A production validator (`solana-validator`) is a full-featured validator that:
- 🌐 **Participates in real consensus**
- 🔒 **Implements full security features**
- 📊 **Provides production metrics**
- 🚀 **Can scale to production workloads**

### **Key Features**
- ✅ **Real consensus mechanism** - Proof of History (PoH)
- ✅ **Full RPC API** - all methods available
- ✅ **Production security** - proper key management
- ✅ **Scalable architecture** - can handle production load

### **Setup Steps**

#### **Step 1: Build Required Tools**
```bash
cargo build --release

# Verify required binaries exist
ls -la target/release/solana-*
# Should include: solana-keygen, solana-genesis, solana-validator, solana-ledger-tool
```

#### **Step 2: Create Genesis Block**
```bash
# Create production genesis with proper parameters
./start-production-validator.sh create-genesis
```

**What this creates:**
- `production-ledger/` - Genesis and initial state
- `mint.json` - Mint authority keypair
- `faucet-keypair.json` - Faucet account keypair
- `production-genesis-hash.txt` - Genesis hash for validation

#### **Step 3: Start the Validator**
```bash
# Start production validator
./start-production-validator.sh start
```

**Key parameters used:**
- `--no-wait-for-vote-to-start-leader` - Critical for single validator operation
- `--full-rpc-api` - Enable all RPC methods
- `--enable-rpc-transaction-history` - Transaction history support
- `--dynamic-port-range 8000-8020` - Network port range

#### **Step 4: Start Faucet (Optional)**
```bash
# Start faucet for token distribution
./start-production-validator.sh start-faucet
```

#### **Step 5: Verify Operation**
```bash
# Check status
./start-production-validator.sh status

# View logs
./start-production-validator.sh logs validator

# Test RPC
curl -s http://localhost:8899 -X POST -H "Content-Type: application/json" \
  -d '{"jsonrpc":"2.0","id":1,"method":"getHealth"}' | jq .
```

## 🔑 Key Configuration Parameters

### **Test Validator Parameters**
```bash
--reset                    # Clear existing data
--quiet                    # Reduce log verbosity
--rpc-port 8899           # RPC endpoint port
--gossip-port 8001        # Gossip network port
--faucet-port 9900        # Faucet service port
```

### **Production Validator Parameters**
```bash
--identity validator-keypair.json           # Validator identity
--vote-account vote-account-keypair.json   # Vote account
--ledger production-ledger                  # Data directory
--rpc-port 8899                            # RPC port
--rpc-bind-address 0.0.0.0                 # RPC bind address
--full-rpc-api                             # Enable all RPC methods
--enable-rpc-transaction-history           # Transaction history
--gossip-port 8001                         # Gossip port
--dynamic-port-range 8000-8020             # Dynamic port range
--expected-genesis-hash <HASH>             # Genesis validation
--no-wait-for-vote-to-start-leader         # Critical for single validator
```

## 🌐 Network Configuration

### **Port Requirements**

| Service | Port | Protocol | Purpose |
|---------|------|----------|---------|
| **RPC** | 8899 | TCP | JSON-RPC API |
| **WebSocket** | 8900 | TCP | Real-time subscriptions |
| **Gossip** | 8001 | UDP | Network discovery |
| **Faucet** | 9900 | TCP | Token distribution |
| **Dynamic** | 8000-8020 | UDP | Repair and serve-repair |

### **Firewall Configuration**

#### **UFW (Ubuntu)**
```bash
sudo ufw allow 8899/tcp  # RPC
sudo ufw allow 8900/tcp  # WebSocket
sudo ufw allow 9900/tcp  # Faucet
sudo ufw allow 8001/udp  # Gossip
sudo ufw allow 8000:8020/udp  # Dynamic range
```

#### **iptables**
```bash
sudo iptables -A INPUT -p tcp --dport 8899 -j ACCEPT
sudo iptables -A INPUT -p tcp --dport 8900 -j ACCEPT
sudo iptables -A INPUT -p tcp --dport 9900 -j ACCEPT
sudo iptables -A INPUT -p udp --dport 8001 -j ACCEPT
sudo iptables -A INPUT -p udp --dport 8000:8020 -j ACCEPT
```

## 🔐 Key Management

### **Required Keypairs**

| Keypair | Purpose | Location | Generated By |
|----------|---------|----------|--------------|
| `validator-keypair.json` | Validator identity | Project root | `solana-keygen new` |
| `vote-account-keypair.json` | Vote account | Project root | `solana-keygen new` |
| `stake-account-keypair.json` | Stake account | Project root | `solana-keygen new` |
| `mint.json` | Mint authority | Project root | `solana-genesis` |
| `faucet-keypair.json` | Faucet account | Project root | `solana-genesis` |

### **Key Generation Commands**
```bash
# Generate validator identity
./target/release/solana-keygen new -o validator-keypair.json --no-bip39-passphrase

# Generate vote account
./target/release/solana-keygen new -o vote-account-keypair.json --no-bip39-passphrase

# Generate stake account
./target/release/solana-keygen new -o stake-account-keypair.json --no-bip39-passphrase
```

### **Security Best Practices**
- 🔒 **Store keys securely** - not in version control
- 🔑 **Use strong passphrases** - for production keys
- 📁 **Backup keys** - multiple secure locations
- 🚫 **Limit access** - only necessary users

## 📊 Genesis Configuration

### **Genesis Parameters**

| Parameter | Value | Purpose |
|-----------|-------|---------|
| `--cluster-type` | `development` | Network type |
| `--hashes-per-tick` | `auto` | PoH configuration |
| `--rent-exemption-threshold` | `2.0` | Account rent threshold |
| `--target-lamports-per-signature` | `5000` | Transaction fees |
| `--lamports-per-byte-year` | `3480` | Storage rent rate |

### **Customizing Genesis**
```bash
# Modify genesis parameters in start-production-validator.sh
./target/release/solana-genesis \
  --ledger production-ledger \
  --bootstrap-validator <VALIDATOR_PUBKEY> <VOTE_PUBKEY> <STAKE_PUBKEY> \
  --faucet-pubkey <FAUCET_PUBKEY> \
  --faucet-lamports 1000000000000000 \
  --bootstrap-stake-authorized-pubkey <VALIDATOR_PUBKEY>
```

## 🧪 Testing Your Setup

### **Basic Functionality Tests**

#### **1. RPC Health Check**
```bash
curl -s http://localhost:8899 -X POST -H "Content-Type: application/json" \
  -d '{"jsonrpc":"2.0","id":1,"method":"getHealth"}' | jq .
```

#### **2. Slot Progression**
```bash
# Get current slot
curl -s http://localhost:8899 -X POST -H "Content-Type: application/json" \
  -d '{"jsonrpc":"2.0","id":1,"method":"getSlot"}' | jq .

# Wait a few seconds and check again
sleep 5
curl -s http://localhost:8899 -X POST -H "Content-Type: application/json" \
  -d '{"jsonrpc":"2.0","id":1,"method":"getSlot"}' | jq .
```

#### **3. Transaction Processing**
```bash
# Create test wallet
./target/release/solana-keygen new -o test-wallet.json --no-bip39-passphrase

# Get test tokens
./target/release/solana airdrop 10 $(./target/release/solana-keygen pubkey test-wallet.json)

# Check balance
./target/release/solana balance $(./target/release/solana-keygen pubkey test-wallet.json)
```

### **Advanced Tests**

#### **1. Program Deployment**
```bash
# Build a simple program
cargo build-bpf --target bpfel-unknown-unknown --release

# Deploy to validator
./target/release/solana program deploy target/bpfel-unknown-unknown/release/your_program.so
```

#### **2. Custom Transactions**
```bash
# Create and send custom transaction
./target/release/solana transfer <RECIPIENT_PUBKEY> 1 --from test-wallet.json
```

## 🚨 Common Issues & Solutions

### **"Haven't landed a vote" Error**
**Problem**: Validator not producing blocks
**Solution**: Use `--no-wait-for-vote-to-start-leader` flag

### **"Method not found" Error**
**Problem**: RPC methods unavailable
**Solution**: Add `--full-rpc-api` flag

### **"Port already in use" Error**
**Problem**: Port conflicts
**Solution**: Kill existing processes or use different ports

### **"Genesis hash mismatch" Error**
**Problem**: Genesis validation failed
**Solution**: Regenerate genesis or check hash

## 📈 Performance Optimization

### **System Tuning**
```bash
# Increase file descriptor limits
echo "* soft nofile 65536" | sudo tee -a /etc/security/limits.conf
echo "* hard nofile 65536" | sudo tee -a /etc/security/limits.conf

# Optimize kernel parameters
echo 'vm.swappiness=1' | sudo tee -a /etc/sysctl.conf
echo 'vm.max_map_count=1000000' | sudo tee -a /etc/sysctl.conf
```

### **Validator Tuning**
```bash
# Optimize for production
--limit-ledger-size 50000000
--enable-rpc-transaction-history
--full-rpc-api
--wal-recovery-mode skip_any_corrupted_record
```

## 🔄 Maintenance & Updates

### **Regular Maintenance**
```bash
# Check validator status
./start-production-validator.sh status

# View logs for issues
./start-production-validator.sh logs validator

# Monitor disk usage
df -h production-ledger/
```

### **Updating Validator**
```bash
# Stop validator
./start-production-validator.sh stop

# Update code
git pull
cargo build --release

# Restart validator
./start-production-validator.sh start
```

### **Backup & Recovery**
```bash
# Backup ledger
cp -r production-ledger production-ledger-backup-$(date +%Y%m%d)

# Backup keys
cp *.json keys-backup/

# Restore from backup
cp -r production-ledger-backup-* production-ledger
```

## 🚀 Next Steps

### **For Development**
1. **Build Programs**: Use `cargo build-bpf` or `cargo build-sbf`
2. **Test Transactions**: Create and send custom transactions
3. **Deploy Programs**: Use `solana program deploy`

### **For Production**
1. **Add Monitoring**: Set up Prometheus and Grafana
2. **Security Hardening**: Implement proper key management
3. **Scaling**: Add more validators to the network

### **For Learning**
1. **Explore RPC API**: Try different methods
2. **Study Consensus**: Understand PoH and voting
3. **Network Analysis**: Monitor gossip and repair

---

**🎉 Your validator is now ready!** 

**Next**: Learn about [Validator Management](./VALIDATOR_MANAGEMENT.md) or explore [Development Workflow](./DEVELOPMENT_WORKFLOW.md).
