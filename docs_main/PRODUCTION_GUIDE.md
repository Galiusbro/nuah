# Production Guide

Advanced guide for deploying and managing production-ready Solana validators with enterprise-grade features.

## 🎯 Production Overview

### **What Makes a Validator "Production Ready"?**

A production validator is designed for:
- 🏭 **24/7 operation** in production environments
- 🔒 **Enterprise security** with proper key management
- 📊 **Professional monitoring** and alerting
- 🚀 **High performance** and scalability
- 🛡️ **Disaster recovery** and backup strategies

### **Production vs Development Differences**

| Aspect | Development | Production |
|--------|-------------|------------|
| **Uptime** | As needed | 99.9%+ |
| **Security** | Basic | Enterprise-grade |
| **Monitoring** | Manual | Automated |
| **Backup** | None | Comprehensive |
| **Documentation** | Minimal | Complete |

## 🏗️ Production Architecture

### **Single Validator Architecture**
```
Production Machine
├── Solana Validator
│   ├── RPC Service (8899)
│   ├── WebSocket Service (8900)
│   ├── Gossip Network (8001)
│   └── TPU Service (8003)
├── Faucet Service (9900)
├── Monitoring Stack
├── Backup System
└── Security Layer
```

### **Multi-Validator Architecture**
```
Production Cluster
├── Load Balancer
├── Validator 1 (Machine 1)
├── Validator 2 (Machine 2)
├── Validator 3 (Machine 3)
├── Shared Storage
├── Monitoring Cluster
└── Backup Cluster
```

### **Hybrid Architecture**
```
Production Setup
├── Primary Validator (Production)
├── Backup Validator (Standby)
├── Test Validator (Development)
├── Shared Genesis
├── Unified Monitoring
└── Centralized Management
```

## 🔐 Production Security

### **Key Management Strategy**

#### **1. Key Storage**
```bash
# Secure key storage structure
/opt/solana/keys/
├── validator-keypair.json      # Encrypted with passphrase
├── vote-account-keypair.json   # Encrypted with passphrase
├── stake-account-keypair.json  # Encrypted with passphrase
├── faucet-keypair.json         # Encrypted with passphrase
└── backup/                     # Encrypted backups
    ├── keys-$(date +%Y%m%d).tar.gpg
    └── keys-$(date +%Y%m%d).tar.gpg
```

#### **2. Key Encryption**
```bash
# Encrypt keys with GPG
gpg --symmetric --cipher-algo AES256 validator-keypair.json

# Decrypt when needed
gpg --decrypt validator-keypair.json.gpg > validator-keypair.json
```

#### **3. Access Control**
```bash
# Restrict key access
chmod 600 /opt/solana/keys/*.json
chown solana:solana /opt/solana/keys/*.json

# Use sudo for operations
sudo -u solana ./start-production-validator.sh start
```

### **Network Security**

#### **1. Firewall Configuration**
```bash
# UFW configuration for production
sudo ufw default deny incoming
sudo ufw default allow outgoing

# Allow only necessary ports
sudo ufw allow 22/tcp                    # SSH
sudo ufw allow 8899/tcp                  # RPC (restrict to specific IPs)
sudo ufw allow 8900/tcp                  # WebSocket (restrict to specific IPs)
sudo ufw allow 8001/udp                  # Gossip
sudo ufw allow 8000:8020/udp            # Dynamic range
sudo ufw allow 9900/tcp                  # Faucet (restrict to specific IPs)

# Enable UFW
sudo ufw enable
```

#### **2. IP Restriction**
```bash
# Restrict RPC access to specific IPs
sudo ufw allow from 192.168.1.0/24 to any port 8899
sudo ufw allow from 10.0.0.0/8 to any port 8899

# Restrict WebSocket access
sudo ufw allow from 192.168.1.0/24 to any port 8900
sudo ufw allow from 10.0.0.0/8 to any port 8900
```

#### **3. VPN Access**
```bash
# Set up VPN for secure access
sudo apt install openvpn

# Configure VPN server
sudo nano /etc/openvpn/server.conf

# Allow VPN traffic
sudo ufw allow 1194/udp
```

### **System Security**

#### **1. User Management**
```bash
# Create dedicated user for Solana
sudo useradd -m -s /bin/bash solana
sudo usermod -aG sudo solana

# Switch to Solana user
sudo su - solana
```

#### **2. Service Isolation**
```bash
# Run validator as service user
sudo systemctl create solana-validator
sudo systemctl enable solana-validator

# Service file: /etc/systemd/system/solana-validator.service
[Unit]
Description=Solana Validator
After=network.target

[Service]
Type=simple
User=solana
Group=solana
WorkingDirectory=/opt/solana
ExecStart=/opt/solana/start-production-validator.sh start
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
```

## 📊 Production Monitoring

### **Monitoring Stack Components**

#### **1. Prometheus Metrics**
```bash
# Validator automatically exports metrics
curl http://localhost:8899/metrics

# Key metrics to monitor
- solana_validator_slot_index
- solana_validator_slot_elapsed
- solana_validator_vote_slots
- solana_validator_tower_vote_latest
- solana_validator_bank_slot
```

#### **2. Grafana Dashboards**
```yaml
# grafana/dashboards/solana-validator.json
{
  "dashboard": {
    "title": "Solana Validator Dashboard",
    "panels": [
      {
        "title": "Slot Progression",
        "type": "graph",
        "targets": [
          {
            "expr": "solana_validator_slot_index",
            "legendFormat": "Current Slot"
          }
        ]
      },
      {
        "title": "Vote Confirmation",
        "type": "graph",
        "targets": [
          {
            "expr": "solana_validator_vote_slots",
            "legendFormat": "Vote Slots"
          }
        ]
      }
    ]
  }
}
```

#### **3. Alerting Rules**
```yaml
# prometheus/rules/solana-alerts.yml
groups:
  - name: solana-validator
    rules:
      - alert: ValidatorDown
        expr: up{job="solana-validator"} == 0
        for: 1m
        labels:
          severity: critical
        annotations:
          summary: "Solana validator is down"
          
      - alert: SlotStuck
        expr: solana_validator_slot_index - solana_validator_slot_index offset 5m < 100
        for: 2m
        labels:
          severity: warning
        annotations:
          summary: "Validator slots are not progressing"
```

### **Log Management**

#### **1. Centralized Logging**
```bash
# Install and configure rsyslog
sudo apt install rsyslog

# Configure log forwarding
sudo nano /etc/rsyslog.conf

# Add to end of file
*.* @log-server:514
```

#### **2. Log Rotation**
```bash
# Configure logrotate for validator logs
sudo nano /etc/logrotate.d/solana-validator

# Configuration
/opt/solana/production-validator.log {
    daily
    rotate 30
    compress
    delaycompress
    missingok
    notifempty
    create 644 solana solana
    postrotate
        systemctl reload solana-validator
    endscript
}
```

#### **3. Log Analysis**
```bash
# Real-time log monitoring
tail -f /opt/solana/production-validator.log | grep -E "(ERROR|WARN|CRITICAL)"

# Log search and analysis
grep "Haven't landed a vote" /opt/solana/production-validator.log
grep "new root" /opt/solana/production-validator.log | tail -10
```

## 🚀 Performance Optimization

### **System Optimization**

#### **1. Kernel Parameters**
```bash
# /etc/sysctl.conf optimizations
vm.swappiness=1
vm.max_map_count=1000000
net.core.rmem_max=134217728
net.core.wmem_max=134217728
net.core.rmem_default=262144
net.core.wmem_default=262144
fs.file-max=1000000
```

#### **2. Disk Optimization**
```bash
# Use high-performance storage
# NVMe SSDs recommended for production

# Optimize filesystem
sudo tune2fs -O has_journal /dev/nvme0n1p1
sudo tune2fs -m 0 /dev/nvme0n1p1

# Mount with optimizations
# /etc/fstab
/dev/nvme0n1p1 /opt/solana ext4 defaults,noatime,nodiratime 0 2
```

#### **3. Memory Optimization**
```bash
# Increase swap for production
sudo fallocate -l 32G /swapfile
sudo chmod 600 /swapfile
sudo mkswap /swapfile
sudo swapon /swapfile

# Add to /etc/fstab
/swapfile none swap sw 0 0
```

### **Validator Optimization**

#### **1. Performance Flags**
```bash
# Production-optimized validator flags
--limit-ledger-size 50000000
--enable-rpc-transaction-history
--full-rpc-api
--wal-recovery-mode skip_any_corrupted_record
--no-wait-for-vote-to-start-leader
--rpc-bind-address 0.0.0.0
--gossip-port 8001
--dynamic-port-range 8000-8020
--expected-genesis-hash <HASH>
```

#### **2. Resource Limits**
```bash
# Set resource limits for validator process
# /etc/security/limits.conf
solana soft nofile 65536
solana hard nofile 65536
solana soft nproc 32768
solana hard nproc 32768
```

## 🔄 Backup & Recovery

### **Backup Strategy**

#### **1. Automated Backups**
```bash
#!/bin/bash
# /opt/solana/scripts/backup.sh

BACKUP_DIR="/opt/solana/backups"
DATE=$(date +%Y%m%d_%H%M%S)

# Create backup directory
mkdir -p "$BACKUP_DIR"

# Backup ledger
tar -czf "$BACKUP_DIR/ledger_$DATE.tar.gz" -C /opt/solana production-ledger/

# Backup keys (encrypted)
tar -czf "$BACKUP_DIR/keys_$DATE.tar.gz" -C /opt/solana keys/
gpg --symmetric --cipher-algo AES256 "$BACKUP_DIR/keys_$DATE.tar.gz"

# Cleanup old backups (keep 30 days)
find "$BACKUP_DIR" -name "*.tar.gz" -mtime +30 -delete
find "$BACKUP_DIR" -name "*.tar.gz.gpg" -mtime +30 -delete

# Upload to remote storage (optional)
# aws s3 cp "$BACKUP_DIR/ledger_$DATE.tar.gz" s3://solana-backups/
```

#### **2. Backup Scheduling**
```bash
# Add to crontab
sudo crontab -e

# Daily backup at 2 AM
0 2 * * * /opt/solana/scripts/backup.sh

# Weekly full backup
0 2 * * 0 /opt/solana/scripts/full-backup.sh
```

#### **3. Recovery Procedures**
```bash
#!/bin/bash
# /opt/solana/scripts/recover.sh

BACKUP_FILE="$1"
RECOVERY_DIR="/opt/solana/recovery"

if [ -z "$BACKUP_FILE" ]; then
    echo "Usage: $0 <backup_file>"
    exit 1
fi

# Stop validator
sudo systemctl stop solana-validator

# Extract backup
mkdir -p "$RECOVERY_DIR"
tar -xzf "$BACKUP_FILE" -C "$RECOVERY_DIR"

# Restore ledger
rm -rf /opt/solana/production-ledger
cp -r "$RECOVERY_DIR/production-ledger" /opt/solana/

# Restore keys (if needed)
# cp -r "$RECOVERY_DIR/keys" /opt/solana/

# Start validator
sudo systemctl start solana-validator

echo "Recovery completed. Check validator status."
```

### **Disaster Recovery**

#### **1. Recovery Time Objectives (RTO)**
- **RTO**: 15 minutes for full recovery
- **RPO**: 1 hour maximum data loss
- **Backup Frequency**: Daily incremental, weekly full

#### **2. Recovery Procedures**
```bash
# 1. Assess damage
./start-production-validator.sh status

# 2. Stop services
sudo systemctl stop solana-validator

# 3. Restore from backup
./scripts/recover.sh /opt/solana/backups/ledger_20241201_020000.tar.gz

# 4. Verify recovery
./start-production-validator.sh start
./start-production-validator.sh status

# 5. Test functionality
curl -s http://localhost:8899 -X POST -H "Content-Type: application/json" \
  -d '{"jsonrpc":"2.0","id":1,"method":"getHealth"}' | jq .
```

## 📈 Scaling Strategies

### **Horizontal Scaling**

#### **1. Multiple Validators**
```bash
# Machine 1: Primary Validator
./start-production-validator.sh start

# Machine 2: Secondary Validator
./start-production-validator.sh start --entrypoint <MACHINE1_IP>:8001

# Machine 3: Tertiary Validator
./start-production-validator.sh start --entrypoint <MACHINE1_IP>:8001
```

#### **2. Load Balancing**
```bash
# Nginx configuration for RPC load balancing
upstream solana_validators {
    server 192.168.1.10:8899;
    server 192.168.1.11:8899;
    server 192.168.1.12:8899;
}

server {
    listen 80;
    server_name rpc.yourdomain.com;
    
    location / {
        proxy_pass http://solana_validators;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }
}
```

### **Vertical Scaling**

#### **1. Resource Upgrades**
```bash
# Monitor resource usage
htop
iotop
nethogs

# Upgrade based on bottlenecks
# - CPU: More cores
# - RAM: More memory
# - Disk: Faster storage
# - Network: Higher bandwidth
```

#### **2. Performance Tuning**
```bash
# CPU optimization
echo 'performance' | sudo tee /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor

# I/O optimization
echo 'deadline' | sudo tee /sys/block/nvme0n1/queue/scheduler

# Network optimization
echo 'net.core.rmem_max=134217728' | sudo tee -a /etc/sysctl.conf
echo 'net.core.wmem_max=134217728' | sudo tee -a /etc/sysctl.conf
```

## 🚨 Production Troubleshooting

### **Common Production Issues**

#### **1. High Memory Usage**
```bash
# Check memory usage
free -h
ps aux --sort=-%mem | head -10

# Identify memory leaks
valgrind --tool=memcheck --leak-check=full ./target/release/solana-validator

# Restart if necessary
sudo systemctl restart solana-validator
```

#### **2. Disk Space Issues**
```bash
# Check disk usage
df -h
du -sh /opt/solana/production-ledger/*

# Clean old snapshots
find /opt/solana/production-ledger/snapshots -name "*.tar.bz2" -mtime +7 -delete

# Clean old accounts
./target/release/solana-ledger-tool --ledger /opt/solana/production-ledger clean
```

#### **3. Network Issues**
```bash
# Check network connectivity
ping -c 4 8.8.8.8
traceroute 8.8.8.8

# Check port availability
netstat -tulpn | grep :8899
ss -tulpn | grep :8899

# Test RPC connectivity
curl -v http://localhost:8899 -X POST -H "Content-Type: application/json" \
  -d '{"jsonrpc":"2.0","id":1,"method":"getHealth"}'
```

### **Emergency Procedures**

#### **1. Validator Unresponsive**
```bash
# 1. Check process status
ps aux | grep solana-validator

# 2. Check system resources
htop
df -h

# 3. Restart validator
sudo systemctl restart solana-validator

# 4. Check logs
./start-production-validator.sh logs validator
```

#### **2. Data Corruption**
```bash
# 1. Stop validator
sudo systemctl stop solana-validator

# 2. Backup corrupted data
cp -r /opt/solana/production-ledger /opt/solana/corrupted-ledger-$(date +%Y%m%d_%H%M%S)

# 3. Restore from backup
./scripts/recover.sh <LATEST_BACKUP>

# 4. Start validator
sudo systemctl start solana-validator
```

## 📋 Production Checklist

### **Pre-Deployment Checklist**
- [ ] **Security**: Keys encrypted and secured
- [ ] **Monitoring**: Prometheus, Grafana, and alerting configured
- [ ] **Backup**: Automated backup system in place
- [ ] **Documentation**: Runbooks and procedures documented
- [ ] **Testing**: Recovery procedures tested
- [ ] **Performance**: Baseline performance established

### **Deployment Checklist**
- [ ] **System**: Optimized kernel parameters
- [ ] **Network**: Firewall and security configured
- [ ] **Storage**: High-performance storage configured
- [ ] **Services**: Systemd services configured
- [ ] **Logging**: Centralized logging configured
- [ ] **Monitoring**: Dashboards and alerts active

### **Post-Deployment Checklist**
- [ ] **Validation**: Validator producing blocks
- [ ] **Performance**: Meeting performance targets
- [ ] **Security**: Security scans completed
- [ ] **Backup**: Backup verification successful
- [ ] **Documentation**: Updated with actual configuration
- [ ] **Team**: Team trained on procedures

## 🚀 Next Steps

### **Immediate Actions**
1. **Implement Security**: Encrypt keys and secure access
2. **Set Up Monitoring**: Deploy Prometheus and Grafana
3. **Configure Backups**: Implement automated backup system
4. **Document Procedures**: Create runbooks and checklists

### **Advanced Features**
1. **Load Balancing**: Implement RPC load balancing
2. **High Availability**: Set up failover systems
3. **Automation**: Implement automated recovery
4. **Compliance**: Add audit logging and compliance features

### **Long-term Planning**
1. **Scaling**: Plan for horizontal scaling
2. **Disaster Recovery**: Implement multi-region backup
3. **Performance**: Continuous performance optimization
4. **Security**: Regular security audits and updates

---

**🎯 Your production validator is now enterprise-ready!**

**Next**: Implement [Monitoring](./MONITORING.md) and [Security](./SECURITY.md) features, or explore [Scaling Strategies](./SCALING.md).
