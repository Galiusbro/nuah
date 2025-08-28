# Troubleshooting Guide

Comprehensive guide for diagnosing and resolving common Solana validator issues.

## 🚨 Emergency Procedures

### **Validator Not Responding**
```bash
# 1. Check if process is running
ps aux | grep solana-validator

# 2. Check system resources
htop
df -h
free -h

# 3. Restart validator
./start-production-validator.sh stop
./start-production-validator.sh start

# 4. Check logs immediately
./start-production-validator.sh logs validator
```

### **RPC Endpoint Down**
```bash
# 1. Test RPC health
curl -s http://localhost:8899 -X POST -H "Content-Type: application/json" \
  -d '{"jsonrpc":"2.0","id":1,"method":"getHealth"}' | jq .

# 2. Check port availability
sudo lsof -i :8899
netstat -tulpn | grep :8899

# 3. Restart if necessary
./start-production-validator.sh restart
```

### **Data Corruption Suspected**
```bash
# 1. Stop validator immediately
./start-production-validator.sh stop

# 2. Backup corrupted data
cp -r production-ledger corrupted-ledger-$(date +%Y%m%d_%H%M%S)

# 3. Restore from backup
./scripts/recover.sh <LATEST_BACKUP>

# 4. Start validator
./start-production-validator.sh start
```

## 🔍 Common Issues & Solutions

### **1. "Haven't landed a vote" Error**

#### **Problem Description**
```
[INFO solana_core::replay_stage] Haven't landed a vote, so skipping my leader slot
```

#### **Root Cause**
- Single validator cannot establish consensus
- Missing `--no-wait-for-vote-to-start-leader` flag
- Network connectivity issues

#### **Solutions**

**Immediate Fix:**
```bash
# Add critical flag to validator startup
--no-wait-for-vote-to-start-leader
```

**Complete Fix:**
```bash
# Stop validator
./start-production-validator.sh stop

# Edit start-production-validator.sh to add flag
# Add: --no-wait-for-vote-to-start-leader

# Restart validator
./start-production-validator.sh start
```

**Verification:**
```bash
# Check logs for successful slot progression
./start-production-validator.sh logs validator | grep -E "(new fork|My next leader slot|voting)"
```

### **2. "Method not found" Error**

#### **Problem Description**
```
Error: RPC response error -32601: Method not found
```

#### **Root Cause**
- Missing `--full-rpc-api` flag
- RPC methods restricted
- Incorrect validator configuration

#### **Solutions**

**Immediate Fix:**
```bash
# Add full RPC API flag
--full-rpc-api
```

**Complete Fix:**
```bash
# Stop validator
./start-production-validator.sh stop

# Edit start-production-validator.sh to add flag
# Add: --full-rpc-api

# Restart validator
./start-production-validator.sh start
```

**Verification:**
```bash
# Test RPC methods
curl -s http://localhost:8899 -X POST -H "Content-Type: application/json" \
  -d '{"jsonrpc":"2.0","id":1,"method":"getSlot"}' | jq .

curl -s http://localhost:8899 -X POST -H "Content-Type: application/json" \
  -d '{"jsonrpc":"2.0","id":1,"method":"getHealth"}' | jq .
```

### **3. "Port already in use" Error**

#### **Problem Description**
```
Error: Address already in use (os error 98)
```

#### **Root Cause**
- Another process using the port
- Previous validator not properly stopped
- Port conflicts with other services

#### **Solutions**

**Find Process Using Port:**
```bash
# Check what's using port 8899
sudo lsof -i :8899

# Check what's using port 8001
sudo lsof -i :8001

# Check what's using port 9900
sudo lsof -i :9900
```

**Kill Conflicting Process:**
```bash
# Kill process by PID
sudo kill -9 <PID>

# Or kill all Solana processes
pkill -f "solana-validator"
pkill -f "solana-faucet"
pkill -f "solana-test-validator"
```

**Prevention:**
```bash
# Always use proper stop commands
./start-production-validator.sh stop

# Check status before starting
./start-production-validator.sh status
```

### **4. "Genesis hash mismatch" Error**

#### **Problem Description**
```
Error: Genesis hash mismatch
```

#### **Root Cause**
- Genesis block corrupted or changed
- Multiple genesis files
- Incorrect genesis hash reference

#### **Solutions**

**Immediate Fix:**
```bash
# Regenerate genesis
./start-production-validator.sh clean
./start-production-validator.sh create-genesis
./start-production-validator.sh start
```

**Verification:**
```bash
# Check genesis hash
cat production-genesis-hash.txt

# Verify with ledger tool
./target/release/solana-ledger-tool genesis-hash --ledger production-ledger
```

**Prevention:**
```bash
# Don't modify genesis after creation
# Backup genesis files before changes
# Use consistent genesis across restarts
```

### **5. "Insufficient funds for fee" Error**

#### **Problem Description**
```
Error: Account XXXX has insufficient funds for fee (0.00001 NUAH)
```

#### **Root Cause**
- Using wrong keypair for transactions
- Account has no SOL for fees
- Incorrect account configuration

#### **Solutions**

**Check Account Balance:**
```bash
# Check balance of account
./target/release/solana balance <ACCOUNT_PUBKEY>

# Check which keypair is configured
./target/release/solana config get
```

**Fix Account Configuration:**
```bash
# Set correct keypair
./target/release/solana config set --keypair faucet-keypair.json

# Or specify keypair explicitly
./target/release/solana transfer <RECIPIENT> <AMOUNT> --from <KEYPAIR_FILE>
```

**Get Test Tokens:**
```bash
# For test validator
./target/release/solana airdrop 10 <ACCOUNT_PUBKEY>

# For production validator
./target/release/solana transfer <ACCOUNT_PUBKEY> 10 --from faucet-keypair.json --allow-unfunded-recipient
```

### **6. "Node is unhealthy" Error**

#### **Problem Description**
```
Error: RPC response error -32005: Node is unhealthy
```

#### **Root Cause**
- Validator not fully initialized
- Network synchronization issues
- Resource constraints

#### **Solutions**

**Wait for Initialization:**
```bash
# Wait 2-5 minutes for full initialization
sleep 300

# Check status
./start-production-validator.sh status
```

**Check System Resources:**
```bash
# Check memory usage
free -h

# Check disk space
df -h

# Check CPU usage
htop
```

**Restart if Necessary:**
```bash
# Restart validator
./start-production-validator.sh restart

# Check logs
./start-production-validator.sh logs validator
```

### **7. "Airdrop request failed" Error**

#### **Problem Description**
```
Error: airdrop request failed. This can happen when the rate limit is reached.
```

#### **Root Cause**
- Faucet not running
- Rate limiting
- Network issues

#### **Solutions**

**Check Faucet Status:**
```bash
# Check if faucet is running
./start-production-validator.sh status

# Start faucet if needed
./start-production-validator.sh start-faucet
```

**Use Alternative Methods:**
```bash
# Transfer from faucet account directly
./target/release/solana transfer <RECIPIENT> 10 --from faucet-keypair.json --allow-unfunded-recipient

# Or use test validator
./start-test-validator.sh
```

**Verify Faucet Balance:**
```bash
# Check faucet account balance
./target/release/solana balance $(./target/release/solana-keygen pubkey faucet-keypair.json)
```

## 🔧 System-Level Issues

### **1. High Memory Usage**

#### **Symptoms**
- System becomes unresponsive
- Validator crashes
- High swap usage

#### **Diagnosis**
```bash
# Check memory usage
free -h
htop

# Check memory by process
ps aux --sort=-%mem | head -10

# Check swap usage
swapon --show
```

#### **Solutions**
```bash
# Increase swap space
sudo fallocate -l 32G /swapfile
sudo chmod 600 /swapfile
sudo mkswap /swapfile
sudo swapon /swapfile

# Add to /etc/fstab
echo '/swapfile none swap sw 0 0' | sudo tee -a /etc/fstab

# Restart validator
./start-production-validator.sh restart
```

### **2. Disk Space Issues**

#### **Symptoms**
- Validator stops working
- "No space left on device" errors
- High disk usage

#### **Diagnosis**
```bash
# Check disk usage
df -h
du -sh production-ledger/*

# Check largest directories
du -sh production-ledger/* | sort -hr | head -10
```

#### **Solutions**
```bash
# Clean old snapshots
find production-ledger/snapshots -name "*.tar.bz2" -mtime +7 -delete

# Clean old accounts
./target/release/solana-ledger-tool --ledger production-ledger clean

# Increase disk space or move to larger disk
```

### **3. Network Connectivity Issues**

#### **Symptoms**
- Validator can't connect to peers
- High packet loss
- Timeout errors

#### **Diagnosis**
```bash
# Test basic connectivity
ping -c 4 8.8.8.8
traceroute 8.8.8.8

# Check port availability
netstat -tulpn | grep :8899
ss -tulpn | grep :8899

# Test RPC connectivity
curl -v http://localhost:8899 -X POST -H "Content-Type: application/json" \
  -d '{"jsonrpc":"2.0","id":1,"method":"getHealth"}'
```

#### **Solutions**
```bash
# Check firewall settings
sudo ufw status
sudo iptables -L

# Allow necessary ports
sudo ufw allow 8899/tcp
sudo ufw allow 8001/udp
sudo ufw allow 8000:8020/udp

# Check network configuration
ip addr show
ip route show
```

## 📊 Performance Issues

### **1. Slow Slot Progression**

#### **Symptoms**
- Slots taking longer than expected
- High latency in block production
- Poor transaction throughput

#### **Diagnosis**
```bash
# Check slot timing
curl -s http://localhost:8899 -X POST -H "Content-Type: application/json" \
  -d '{"jsonrpc":"2.0","id":1,"method":"getSlot"}' | jq .

# Wait and check again
sleep 10
curl -s http://localhost:8899 -X POST -H "Content-Type: application/json" \
  -d '{"jsonrpc":"2.0","id":1,"method":"getSlot"}' | jq .
```

#### **Solutions**
```bash
# Optimize system performance
echo 'performance' | sudo tee /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor

# Check for resource bottlenecks
htop
iotop
nethogs

# Restart validator
./start-production-validator.sh restart
```

### **2. High Transaction Latency**

#### **Symptoms**
- Transactions taking long time to confirm
- High confirmation delays
- Poor user experience

#### **Diagnosis**
```bash
# Check transaction status
./target/release/solana confirm <SIGNATURE>

# Check network congestion
curl -s http://localhost:8899 -X POST -H "Content-Type: application/json" \
  -d '{"jsonrpc":"2.0","id":1,"method":"getRecentPerformanceSamples"}' | jq .
```

#### **Solutions**
```bash
# Optimize validator parameters
--limit-ledger-size 50000000
--enable-rpc-transaction-history
--full-rpc-api

# Check system resources
htop
df -h
free -h
```

## 🚨 Critical Error Recovery

### **1. Validator Won't Start**

#### **Recovery Steps**
```bash
# 1. Check system resources
htop
df -h
free -h

# 2. Check for conflicting processes
ps aux | grep solana
sudo lsof -i :8899

# 3. Clean and restart
./start-production-validator.sh clean
./start-production-validator.sh create-genesis
./start-production-validator.sh start

# 4. Check logs immediately
./start-production-validator.sh logs validator
```

### **2. Data Corruption**

#### **Recovery Steps**
```bash
# 1. Stop validator immediately
./start-production-validator.sh stop

# 2. Backup corrupted data
cp -r production-ledger corrupted-ledger-$(date +%Y%m%d_%H%M%S)

# 3. Restore from backup
./scripts/recover.sh <LATEST_BACKUP>

# 4. Verify restoration
./start-production-validator.sh status

# 5. Start validator
./start-production-validator.sh start
```

### **3. Complete System Failure**

#### **Recovery Steps**
```bash
# 1. Reboot system if necessary
sudo reboot

# 2. Check system health
htop
df -h
free -h

# 3. Restore from backup
./scripts/recover.sh <LATEST_BACKUP>

# 4. Start services
./start-production-validator.sh start
./start-production-validator.sh start-faucet

# 5. Verify operation
./start-production-validator.sh status
```

## 🔍 Diagnostic Commands

### **System Health Check**
```bash
#!/bin/bash
# Complete system health check

echo "=== System Health Check ==="

echo "1. Memory Usage:"
free -h

echo "2. Disk Usage:"
df -h

echo "3. CPU Usage:"
top -bn1 | grep "Cpu(s)"

echo "4. Process Status:"
ps aux | grep solana

echo "5. Port Status:"
netstat -tulpn | grep -E "(8899|8001|9900)"

echo "6. Validator Status:"
./start-production-validator.sh status

echo "7. RPC Health:"
curl -s http://localhost:8899 -X POST -H "Content-Type: application/json" \
  -d '{"jsonrpc":"2.0","id":1,"method":"getHealth"}' | jq .

echo "8. Current Slot:"
curl -s http://localhost:8899 -X POST -H "Content-Type: application/json" \
  -d '{"jsonrpc":"2.0","id":1,"method":"getSlot"}' | jq .
```

### **Network Diagnostic**
```bash
#!/bin/bash
# Network connectivity check

echo "=== Network Diagnostic ==="

echo "1. Basic Connectivity:"
ping -c 4 8.8.8.8

echo "2. DNS Resolution:"
nslookup google.com

echo "3. Port Availability:"
sudo lsof -i :8899
sudo lsof -i :8001
sudo lsof -i :9900

echo "4. Firewall Status:"
sudo ufw status

echo "5. Network Interfaces:"
ip addr show

echo "6. Routing:"
ip route show
```

## 📋 Troubleshooting Checklist

### **Before Starting Troubleshooting**
- [ ] **Document the issue** - What happened? When? What were you doing?
- [ ] **Check recent changes** - What changed before the issue appeared?
- [ ] **Gather information** - Error messages, logs, system status
- [ ] **Identify scope** - Is it affecting just the validator or the entire system?

### **During Troubleshooting**
- [ ] **Start with simple checks** - Process status, system resources
- [ ] **Check logs first** - Most issues are logged
- [ ] **Test one fix at a time** - Don't make multiple changes simultaneously
- [ ] **Document what you try** - Keep track of attempted solutions

### **After Resolution**
- [ ] **Verify the fix** - Test that the issue is actually resolved
- [ ] **Document the solution** - Write down what fixed it
- [ ] **Implement prevention** - What can be done to prevent this in the future?
- [ ] **Update procedures** - Modify runbooks if necessary

## 🆘 Getting Help

### **Information to Provide**
When seeking help, provide:

1. **Error messages** - Exact text and context
2. **System information** - OS, Solana version, hardware specs
3. **What you were doing** - Steps that led to the issue
4. **What you've tried** - Solutions already attempted
5. **Logs** - Relevant log excerpts
6. **Configuration** - Current validator configuration

### **Where to Get Help**
1. **Check this guide first** - Most common issues are covered here
2. **Review logs** - Use `./start-production-validator.sh logs validator`
3. **Check system resources** - Use diagnostic commands above
4. **Search documentation** - Look for similar issues
5. **Community support** - Solana Discord, GitHub issues

---

**🔧 Armed with these troubleshooting tools, you can resolve most validator issues!**

**Next**: Learn about [Monitoring](./MONITORING.md) to prevent issues before they occur, or explore [Production Guide](./PRODUCTION_GUIDE.md) for advanced configurations.
