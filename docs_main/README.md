# Solana Validator Documentation

This documentation provides comprehensive instructions for setting up and managing Solana validators for development, testing, and production use.

## 📚 Documentation Structure

### **Core Setup**
- [**Quick Start Guide**](./QUICK_START.md) - Get up and running in minutes
- [**Validator Setup**](./VALIDATOR_SETUP.md) - Complete validator configuration
- [**Production Guide**](./PRODUCTION_GUIDE.md) - Production validator deployment

### **Management & Operations**
- [**Validator Management**](./VALIDATOR_MANAGEMENT.md) - Start, stop, and monitor validators
- [**Troubleshooting**](./TROUBLESHOOTING.md) - Common issues and solutions
- [**Monitoring**](./MONITORING.md) - Health checks and metrics

### **Development & Testing**
- [**Development Workflow**](./DEVELOPMENT_WORKFLOW.md) - Building and testing programs
- [**Testing Strategies**](./TESTING_STRATEGIES.md) - Different testing approaches

### **Reference**
- [**Scripts Reference**](./SCRIPTS_REFERENCE.md) - All available scripts and commands
- [**Configuration Files**](./CONFIGURATION_FILES.md) - Configuration examples
- [**API Reference**](./API_REFERENCE.md) - RPC endpoints and usage

## 🚀 Quick Start

### **1. Build the Project**
```bash
cargo build --release
```

### **2. Choose Your Validator Type**

#### **For Development & Testing:**
```bash
# Simple test validator with built-in faucet
./start-test-validator.sh

# Or use the test airdrop script
./test-airdrop.sh
```

#### **For Production & Advanced Testing:**
```bash
# Create production genesis
./start-production-validator.sh create-genesis

# Start production validator
./start-production-validator.sh start

# Start faucet (optional)
./start-production-validator.sh start-faucet
```

### **3. Verify Operation**
```bash
# Check status
./start-production-validator.sh status

# View logs
./start-production-validator.sh logs validator
```

## 🎯 Key Concepts

### **Validator Types**

| Type | Purpose | Complexity | Features |
|------|---------|------------|----------|
| **Test Validator** | Development & Testing | Low | Built-in faucet, simple setup |
| **Production Validator** | Production & Advanced Testing | Medium | Full functionality, custom genesis |

### **Network Modes**

- **Local Network**: Single or multiple validators on one machine
- **Devnet**: Connect to Solana devnet
- **Testnet**: Connect to Solana testnet
- **Mainnet**: Connect to Solana mainnet (read-only)

## 🔧 Prerequisites

- **Rust**: Latest stable version
- **Solana**: Built from source or installed
- **System**: 8GB+ RAM, 100GB+ disk space
- **Network**: Ports 8001, 8899, 8900 available

## 📖 Next Steps

1. **Start with [Quick Start Guide](./QUICK_START.md)** for immediate setup
2. **Read [Validator Setup](./VALIDATOR_SETUP.md)** for complete understanding
3. **Use [Validator Management](./VALIDATOR_MANAGEMENT.md)** for operations
4. **Reference [Scripts Reference](./SCRIPTS_REFERENCE.md)** for all commands

## 🤝 Support

- **Issues**: Check [Troubleshooting](./TROUBLESHOOTING.md) first
- **Questions**: Review [FAQ](./FAQ.md) section
- **Advanced**: See [Production Guide](./PRODUCTION_GUIDE.md)

---

**Ready to get started?** Begin with the [Quick Start Guide](./QUICK_START.md)!
