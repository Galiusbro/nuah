# Quick Start Guide

Get your Solana validator up and running in minutes! This guide covers the essential steps for both development and production use.

## 🚀 Prerequisites

### **System Requirements**
- **RAM**: Minimum 8GB, recommended 16GB+
- **Disk**: Minimum 100GB SSD, recommended 500GB+
- **CPU**: 4+ cores recommended
- **Network**: Ports 8001, 8899, 8900 available

### **Software Requirements**
- **Rust**: Latest stable version
- **Solana**: Built from source (recommended) or installed
- **Git**: For cloning the repository

## ⚡ 5-Minute Setup

### **Step 1: Build the Project**
```bash
# Clone and build (if not already done)
cargo build --release
```

**Expected output**: Build completes successfully with binaries in `target/release/`

### **Step 2: Choose Your Path**

#### **Option A: Quick Development (Recommended for beginners)**
```bash
# Start test validator with built-in faucet
./start-test-validator.sh
```

**What this gives you:**
- ✅ Working validator in seconds
- ✅ Built-in faucet for testing
- ✅ All RPC methods available
- ✅ Perfect for development

#### **Option B: Production Setup (Advanced users)**
```bash
# Create production genesis
./start-production-validator.sh create-genesis

# Start production validator
./start-production-validator.sh start

# Start faucet (optional)
./start-production-validator.sh start-faucet
```

**What this gives you:**
- ✅ Full production validator
- ✅ Custom genesis configuration
- ✅ Real consensus mechanism
- ✅ Advanced testing capabilities

### **Step 3: Verify Everything Works**
```bash
# Check RPC health
curl -s http://localhost:8899 -X POST -H "Content-Type: application/json" \
  -d '{"jsonrpc":"2.0","id":1,"method":"getHealth"}' | jq .

# Check current slot
curl -s http://localhost:8899 -X POST -H "Content-Type: application/json" \
  -d '{"jsonrpc":"2.0","id":1,"method":"getSlot"}' | jq .
```

**Expected output**: `{"result":"ok"}` and current slot number

### **Step 4: Test Basic Operations**

#### **Create a Test Wallet**
```bash
./target/release/solana-keygen new -o test-wallet.json --no-bip39-passphrase
```

#### **Get Test Tokens**
```bash
# For test validator (built-in faucet)
./target/release/solana airdrop 10 $(./target/release/solana-keygen pubkey test-wallet.json)

# For production validator (via faucet account)
./target/release/solana transfer $(./target/release/solana-keygen pubkey test-wallet.json) 10 \
  --from faucet-keypair.json --allow-unfunded-recipient
```

#### **Check Balance**
```bash
./target/release/solana balance $(./target/release/solana-keygen pubkey test-wallet.json)
```

## 🎯 Quick Commands Reference

### **Test Validator**
```bash
# Start
./start-test-validator.sh

# Stop (Ctrl+C)
# Or kill process
pkill -f "solana-test-validator"
```

### **Production Validator**
```bash
# Status
./start-production-validator.sh status

# Start
./start-production-validator.sh start

# Stop
./start-production-validator.sh stop

# Logs
./start-production-validator.sh logs validator

# Clean (reset everything)
./start-production-validator.sh clean
```

### **CLI Operations**
```bash
# Set RPC URL
./target/release/solana config set --url http://localhost:8899

# Set keypair
./target/release/solana config set --keypair faucet-keypair.json

# Check cluster version
./target/release/solana cluster-version
```

## 🔍 Troubleshooting Quick Fixes

### **"Port already in use"**
```bash
# Find and kill process using port 8899
sudo lsof -i :8899
sudo kill -9 <PID>
```

### **"Validator not responding"**
```bash
# Check if process is running
ps aux | grep solana-validator

# Restart if needed
./start-production-validator.sh stop
./start-production-validator.sh start
```

### **"Insufficient funds"**
```bash
# For test validator
./target/release/solana airdrop 10 <PUBKEY>

# For production validator
./target/release/solana transfer <PUBKEY> 10 --from faucet-keypair.json --allow-unfunded-recipient
```

## 📊 What You Should See

### **Successful Startup**
```
✅ Валидатор: запущен (PID: XXXXX)
✅ RPC: доступен (http://localhost:8899)
✅ Genesis: создан (Hash: XXXX...)
```

### **Healthy Logs**
```
[INFO] new fork:72 parent:71 (leader) root:40
[INFO] My next leader slot is 72
[INFO] voting: 71 100.0%
```

### **Working RPC**
```json
{
  "jsonrpc": "2.0",
  "result": "ok",
  "id": 1
}
```

## 🚀 Next Steps

### **For Developers**
1. **Build Programs**: Use `cargo build-bpf` or `cargo build-sbf`
2. **Deploy Programs**: Use `solana program deploy`
3. **Test Transactions**: Create and send custom transactions

### **For Validators**
1. **Monitor Performance**: Check logs and metrics
2. **Scale Up**: Add more validators to the network
3. **Production Hardening**: Security and monitoring setup

### **For Learning**
1. **Explore RPC Methods**: Try different API calls
2. **Understand Consensus**: Watch slot progression
3. **Study Genesis**: Examine network configuration

## ❓ Still Having Issues?

1. **Check [Troubleshooting Guide](./TROUBLESHOOTING.md)**
2. **Review [Validator Setup](./VALIDATOR_SETUP.md)**
3. **Look at logs**: `./start-production-validator.sh logs validator`

---

**🎉 Congratulations!** You now have a working Solana validator. 

**Next**: Dive deeper with the [Validator Setup Guide](./VALIDATOR_SETUP.md) or start building with the [Development Workflow](./DEVELOPMENT_WORKFLOW.md)!
