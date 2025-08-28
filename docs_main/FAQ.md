# Frequently Asked Questions (FAQ)

Common questions and answers about Solana validators, setup, and operation.

## 🚀 General Questions

### **Q: What is a Solana validator?**

**A**: A Solana validator is a node that participates in the Solana network by:
- **Validating transactions** and blocks
- **Participating in consensus** through Proof of History (PoH)
- **Storing blockchain data** and state
- **Providing RPC services** for clients
- **Contributing to network security** and decentralization

### **Q: What's the difference between test and production validators?**

**A**: 

| Aspect | Test Validator | Production Validator |
|--------|----------------|---------------------|
| **Purpose** | Development & testing | Production & real networks |
| **Setup** | Instant, built-in faucet | Requires genesis creation |
| **Consensus** | Simplified, single node | Full PoH consensus |
| **Performance** | Basic, development focused | Optimized, production ready |
| **Security** | Basic | Enterprise-grade |
| **Use Case** | Learning, development | Real applications, production |

### **Q: Can I run multiple validators on one machine?**

**A**: **Yes, but with limitations:**

- **Development**: 2-3 validators on powerful machines (32GB+ RAM, 16+ cores)
- **Production**: **Not recommended** - use separate machines for reliability
- **Testing**: Multiple validators for consensus testing is possible

**Key considerations:**
- Resource competition (CPU, RAM, disk I/O)
- Port conflicts (use different ports for each)
- Single point of failure
- Performance degradation

## 🔧 Setup & Configuration

### **Q: How long does it take to set up a validator?**

**A**: 
- **Test Validator**: 2-5 minutes
- **Production Validator**: 10-30 minutes
- **Production with monitoring**: 1-2 hours
- **Enterprise setup**: 4-8 hours

### **Q: What are the minimum system requirements?**

**A**: 
- **RAM**: 8GB minimum, 16GB+ recommended
- **CPU**: 4+ cores, 8+ cores recommended
- **Disk**: 100GB+ SSD, 500GB+ NVMe recommended
- **Network**: 100+ Mbps, low latency
- **OS**: Linux (Ubuntu 20.04+ recommended)

### **Q: Do I need to create my own genesis block?**

**A**: 
- **Test Validator**: No - uses built-in genesis
- **Production Validator**: Yes - creates custom genesis
- **Public Networks**: No - connects to existing genesis

**When you need custom genesis:**
- Private networks
- Custom tokenomics
- Development/testing
- Research purposes

### **Q: What ports do I need to open?**

**A**: 

| Port | Protocol | Purpose | Required |
|------|----------|---------|----------|
| **8899** | TCP | RPC API | Yes |
| **8900** | TCP | WebSocket | Optional |
| **8001** | UDP | Gossip | Yes |
| **8000-8020** | UDP | Dynamic range | Yes |
| **9900** | TCP | Faucet | Optional |

## 🚨 Common Issues

### **Q: Why does my validator show "Haven't landed a vote"?**

**A**: This is the most common issue! **Root cause**: Single validators can't establish consensus.

**Solution**: Add the critical flag:
```bash
--no-wait-for-vote-to-start-leader
```

**Why this happens:**
- Solana requires multiple validators for consensus
- Single validator can't "land votes" from others
- This flag bypasses the voting requirement
- Allows single validator to produce blocks immediately

### **Q: Why do I get "Method not found" errors?**

**A**: Missing `--full-rpc-api` flag.

**Solution**:
```bash
--full-rpc-api
```

**What this does:**
- Enables all RPC methods
- Includes airdrop, transfer, and other methods
- Required for full functionality
- Default is restricted API for security

### **Q: Why can't I connect to my validator from outside?**

**A**: Firewall/network configuration issues.

**Check these:**
1. **Firewall rules** - Allow necessary ports
2. **Network binding** - Use `0.0.0.0` not `127.0.0.1`
3. **Cloud security groups** - AWS, GCP, Azure settings
4. **Router configuration** - Port forwarding if needed

**Quick fix**:
```bash
# UFW (Ubuntu)
sudo ufw allow 8899/tcp
sudo ufw allow 8001/udp
sudo ufw allow 8000:8020/udp
```

### **Q: Why does airdrop fail?**

**A**: Several possible causes:

**For Test Validator:**
- Built-in faucet should work automatically
- Check if validator is fully started

**For Production Validator:**
- Faucet service not running
- Faucet account has no funds
- Rate limiting

**Solutions**:
```bash
# Start faucet
./start-production-validator.sh start-faucet

# Check faucet balance
./target/release/solana balance $(./target/release/solana-keygen pubkey faucet-keypair.json)

# Transfer directly instead of airdrop
./target/release/solana transfer <RECIPIENT> 10 --from faucet-keypair.json --allow-unfunded-recipient
```

## 💰 Token & Economics

### **Q: How do I get test tokens?**

**A**: 

**Test Validator (Automatic)**:
```bash
./target/release/solana airdrop 10 <PUBKEY>
```

**Production Validator (Manual)**:
```bash
# Transfer from faucet account
./target/release/solana transfer <PUBKEY> 10 --from faucet-keypair.json --allow-unfunded-recipient
```

**Public Networks**:
```bash
# Devnet
./target/release/solana airdrop 2 <PUBKEY> --url https://api.devnet.solana.com

# Testnet
./target/release/solana airdrop 1 <PUBKEY> --url https://api.testnet.solana.com
```

### **Q: How much SOL does my faucet account have?**

**A**: Check faucet balance:
```bash
./target/release/solana balance $(./target/release/solana-keygen pubkey faucet-keypair.json)
```

**Default amounts**:
- **Production genesis**: 1,000,000 SOL (1 billion lamports)
- **Test validator**: Unlimited (built-in)
- **Public networks**: Varies by network

### **Q: Can I change the initial token supply?**

**A**: **Yes** - modify genesis creation parameters.

**Edit the script**:
```bash
# In start-production-validator.sh
--faucet-lamports 2000000000000000  # 2 billion lamports = 2,000,000 SOL
```

**Or create custom genesis**:
```bash
./target/release/solana-genesis \
  --ledger production-ledger \
  --bootstrap-validator <VALIDATOR_PUBKEY> <VOTE_PUBKEY> <STAKE_PUBKEY> \
  --faucet-pubkey <FAUCET_PUBKEY> \
  --faucet-lamports 5000000000000000 \  # 5 billion lamports
  --bootstrap-stake-authorized-pubkey <VALIDATOR_PUBKEY>
```

## 🌐 Network & Connectivity

### **Q: Can I connect my validator to public networks?**

**A**: **Yes** - but with limitations.

**Devnet/Testnet**:
```bash
# Start with entrypoint
./target/release/solana-validator \
  --entrypoint devnet.solana.com:8001 \
  --expected-genesis-hash 5eykt4UsFv8P8NJdTREpYQvqdKk1CVVcypHk3P4Z6uoL
```

**Mainnet**:
- **Read-only** mode only
- **No voting** participation
- **Large data** requirements
- **High bandwidth** needs

### **Q: How do I make my validator public?**

**A**: 

**1. Network Configuration**:
```bash
# Bind to all interfaces
--rpc-bind-address 0.0.0.0
--gossip-host 0.0.0.0
```

**2. Firewall Setup**:
```bash
sudo ufw allow 8899/tcp  # RPC
sudo ufw allow 8001/udp  # Gossip
sudo ufw allow 8000:8020/udp  # Dynamic range
```

**3. DNS/Public IP**:
- Get static public IP
- Configure DNS (e.g., `rpc.yourdomain.com`)
- Consider load balancer for multiple validators

**4. Security**:
- Restrict RPC access to specific IPs
- Use VPN for admin access
- Implement rate limiting

### **Q: Can other validators join my network?**

**A**: **Yes** - but requires proper configuration.

**For other validators to join**:
```bash
# Other validators use your entrypoint
./target/release/solana-validator \
  --entrypoint YOUR_IP:8001 \
  --expected-genesis-hash YOUR_GENESIS_HASH
```

**Requirements**:
- Your validator must be running and accessible
- Same genesis hash
- Network connectivity
- Proper port configuration

## 🔒 Security & Best Practices

### **Q: How do I secure my validator keys?**

**A**: 

**1. File Permissions**:
```bash
chmod 600 *.json
chown $USER:$USER *.json
```

**2. Encryption**:
```bash
# Encrypt with GPG
gpg --symmetric --cipher-algo AES256 validator-keypair.json

# Decrypt when needed
gpg --decrypt validator-keypair.json.gpg > validator-keypair.json
```

**3. Secure Storage**:
```bash
# Move to secure location
mkdir -p ~/.solana/keys
mv *.json ~/.solana/keys/
chmod 700 ~/.solana/keys
```

**4. Access Control**:
```bash
# Create dedicated user
sudo useradd -m -s /bin/bash solana
sudo chown -R solana:solana ~/.solana
```

### **Q: Should I run my validator as root?**

**A**: **NO!** Always run as dedicated user.

**Create dedicated user**:
```bash
sudo useradd -m -s /bin/bash solana
sudo usermod -aG sudo solana
sudo su - solana
```

**Benefits**:
- Security isolation
- Limited permissions
- Easier backup/restore
- Better process management

### **Q: How do I backup my validator?**

**A**: 

**Automated backup script**:
```bash
#!/bin/bash
BACKUP_DIR="/opt/solana/backups"
DATE=$(date +%Y%m%d_%H%M%S)

# Backup ledger
tar -czf "$BACKUP_DIR/ledger_$DATE.tar.gz" -C /opt/solana production-ledger/

# Backup keys (encrypted)
tar -czf "$BACKUP_DIR/keys_$DATE.tar.gz" -C /opt/solana keys/
gpg --symmetric --cipher-algo AES256 "$BACKUP_DIR/keys_$DATE.tar.gz"

# Cleanup old backups
find "$BACKUP_DIR" -name "*.tar.gz" -mtime +30 -delete
```

**Schedule with cron**:
```bash
# Daily backup at 2 AM
0 2 * * * /opt/solana/scripts/backup.sh
```

## 📊 Monitoring & Maintenance

### **Q: How do I monitor my validator?**

**A**: 

**1. Built-in Metrics**:
```bash
# Prometheus metrics endpoint
curl http://localhost:8899/metrics

# Key metrics to watch
- solana_validator_slot_index
- solana_validator_vote_slots
- solana_validator_tower_vote_latest
```

**2. Status Commands**:
```bash
# Check status
./start-production-validator.sh status

# View logs
./start-production-validator.sh logs validator

# Check RPC health
curl -s http://localhost:8899 -X POST -H "Content-Type: application/json" \
  -d '{"jsonrpc":"2.0","id":1,"method":"getHealth"}' | jq .
```

**3. System Monitoring**:
```bash
# Resource usage
htop
df -h
free -h

# Network status
netstat -tulpn | grep :8899
```

### **Q: How often should I restart my validator?**

**A**: 

**Generally**: **Don't restart unless necessary**

**Restart when**:
- System updates
- Configuration changes
- Performance issues
- Security patches
- Memory leaks
- Network changes

**Best practices**:
- Monitor continuously
- Restart during maintenance windows
- Test changes in development first
- Have backup/restore procedures ready

### **Q: How do I update my validator?**

**A**: 

**Update process**:
```bash
# 1. Stop validator
./start-production-validator.sh stop

# 2. Backup current state
cp -r production-ledger production-ledger-backup-$(date +%Y%m%d)

# 3. Update code
git pull
cargo build --release

# 4. Restart validator
./start-production-validator.sh start

# 5. Verify operation
./start-production-validator.sh status
```

**Rollback if needed**:
```bash
# Restore from backup
cp -r production-ledger-backup-* production-ledger
./start-production-validator.sh start
```

## 🚀 Performance & Optimization

### **Q: How can I improve validator performance?**

**A**: 

**1. System Optimization**:
```bash
# CPU governor
echo 'performance' | sudo tee /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor

# Kernel parameters
echo 'vm.swappiness=1' | sudo tee -a /etc/sysctl.conf
echo 'vm.max_map_count=1000000' | sudo tee -a /etc/sysctl.conf
```

**2. Storage Optimization**:
```bash
# Use NVMe SSDs
# Optimize filesystem
sudo tune2fs -O has_journal /dev/nvme0n1p1
sudo tune2fs -m 0 /dev/nvme0n1p1
```

**3. Validator Flags**:
```bash
--limit-ledger-size 50000000
--enable-rpc-transaction-history
--full-rpc-api
--wal-recovery-mode skip_any_corrupted_record
```

### **Q: How many transactions can my validator handle?**

**A**: **Depends on hardware and configuration**

**Typical performance**:
- **Basic setup**: 1,000-5,000 TPS
- **Optimized setup**: 10,000-50,000 TPS
- **Enterprise setup**: 50,000+ TPS

**Limiting factors**:
- CPU cores and speed
- Memory capacity and speed
- Storage I/O performance
- Network bandwidth
- Transaction complexity

**Optimization tips**:
- Use high-performance hardware
- Optimize system parameters
- Monitor resource usage
- Scale horizontally (multiple validators)

## 🔄 Troubleshooting

### **Q: My validator won't start - what do I do?**

**A**: **Follow this checklist**:

**1. Check system resources**:
```bash
htop
df -h
free -h
```

**2. Check for conflicts**:
```bash
ps aux | grep solana
sudo lsof -i :8899
```

**3. Check logs**:
```bash
./start-production-validator.sh logs validator
tail -f production-validator.log
```

**4. Clean and restart**:
```bash
./start-production-validator.sh clean
./start-production-validator.sh create-genesis
./start-production-validator.sh start
```

### **Q: How do I know if my validator is working correctly?**

**A**: **Check these indicators**:

**1. Process Status**:
```bash
./start-production-validator.sh status
ps aux | grep solana-validator
```

**2. RPC Health**:
```bash
curl -s http://localhost:8899 -X POST -H "Content-Type: application/json" \
  -d '{"jsonrpc":"2.0","id":1,"method":"getHealth"}' | jq .
```

**3. Slot Progression**:
```bash
# Get current slot
curl -s http://localhost:8899 -X POST -H "Content-Type: application/json" \
  -d '{"jsonrpc":"2.0","id":1,"method":"getSlot"}' | jq .

# Wait and check again
sleep 10
curl -s http://localhost:8899 -X POST -H "Content-Type: application/json" \
  -d '{"jsonrpc":"2.0","id":1,"method":"getSlot"}' | jq .
```

**4. Log Analysis**:
```bash
# Look for successful slot progression
./start-production-validator.sh logs validator | grep -E "(new fork|My next leader slot|voting)"

# Look for errors
./start-production-validator.sh logs validator | grep -E "(ERROR|WARN|CRITICAL)"
```

### **Q: What should I do if I see errors in the logs?**

**A**: **Follow this process**:

**1. Identify the error**:
```bash
# Look for error patterns
grep "ERROR" production-validator.log
grep "WARN" production-validator.log
```

**2. Check the [Troubleshooting Guide](./TROUBLESHOOTING.md)**

**3. Common error patterns**:
- **"Haven't landed a vote"** → Add `--no-wait-for-vote-to-start-leader`
- **"Method not found"** → Add `--full-rpc-api`
- **"Port already in use"** → Kill conflicting processes
- **"Genesis hash mismatch"** → Regenerate genesis

**4. If unsure**:
- Document the error
- Check system resources
- Restart the validator
- Seek help with full context

## 📚 Learning & Development

### **Q: Where can I learn more about Solana?**

**A**: 

**Official Resources**:
- [Solana Documentation](https://docs.solana.com/)
- [Solana Cookbook](https://solanacookbook.com/)
- [Solana GitHub](https://github.com/solana-labs/solana)

**Community Resources**:
- Solana Discord
- Solana Forums
- YouTube tutorials
- Community blogs

**Development Resources**:
- [Solana Program Library](https://github.com/solana-labs/solana-program-library)
- [Anchor Framework](https://www.anchor-lang.com/)
- [Solana Playground](https://playground.solana.com/)

### **Q: How do I develop programs for Solana?**

**A**: 

**1. Setup Development Environment**:
```bash
# Install Rust
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh

# Install Solana CLI
sh -c "$(curl -sSfL https://release.solana.com/stable/install)"

# Install Anchor (optional)
cargo install --git https://github.com/coral-xyz/anchor avm --locked --force
```

**2. Build Programs**:
```bash
# BPF programs (older)
cargo build-bpf

# SBF programs (newer)
cargo build-sbf
```

**3. Deploy to Validator**:
```bash
# Deploy program
./target/release/solana program deploy target/deploy/your_program.so

# Set program ID
./target/release/solana program set-upgrade-authority <PROGRAM_ID> --final
```

**4. Test Programs**:
```bash
# Use your validator for testing
./start-production-validator.sh start

# Deploy and test
./target/release/solana program deploy target/deploy/your_program.so
```

---

**🎯 These FAQs cover the most common questions!**

**Still have questions?** Check the [Troubleshooting Guide](./TROUBLESHOOTING.md) or explore the [Production Guide](./PRODUCTION_GUIDE.md) for more detailed information.
