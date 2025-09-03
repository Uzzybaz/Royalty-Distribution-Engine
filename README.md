# 🎵 Royalty Distribution Engine

A transparent and automated royalty distribution system built on Stacks blockchain for musicians, producers, and songwriters. Every time a song is streamed or purchased on a partnering platform, the smart contract automatically splits and disburses payments according to pre-defined, unchangeable rules.

## ✨ Features

- 🔐 **Immutable Royalty Splits**: Once set, distribution percentages cannot be altered without artist consent
- ⚡ **Automated Payments**: Instant distribution upon payment receipt
- 👥 **Multi-Collaborator Support**: Support for up to 10 collaborators per song
- 📊 **Transparent Tracking**: Full audit trail of all transactions and earnings
- 🎛️ **Platform Integration**: Track earnings from different streaming/purchase platforms
- 🛡️ **Owner Controls**: Emergency pause functionality and song management

## 🚀 Quick Start

### Prerequisites
- [Clarinet](https://github.com/hirosystems/clarinet) installed
- Stacks wallet with STX for transactions

### Installation

1. Clone the repository:
```bash
git clone https://github.com/your-username/Royalty-Distribution-Engine
cd Royalty-Distribution-Engine
```

2. Check contract compilation:
```bash
clarinet check
```

3. Run tests:
```bash
clarinet test
```

## 📖 Usage Guide

### 1. 🎼 Register a New Song

Register a song with collaborators and their royalty percentages:

```clarity
(contract-call? .Royalty-Distribution-Engine register-song 
  u1 ;; song-id
  "My Amazing Song" ;; title
  (list 
    { collaborator: 'SP1FQKN..., role: "artist", percentage: u5000 }    ;; 50%
    { collaborator: 'SP2ABCD..., role: "producer", percentage: u3000 }  ;; 30%  
    { collaborator: 'SP3EFGH..., role: "writer", percentage: u2000 }    ;; 20%
  )
)
```

**Important**: Percentages must total exactly 10,000 (representing 100%)

### 2. 💰 Distribute Royalties

When earnings come in from platforms, distribute them automatically:

```clarity
(contract-call? .Royalty-Distribution-Engine distribute-royalty 
  u1 ;; song-id
  u1000000 ;; amount in microSTX
  "Spotify" ;; platform name
)
```

### 3. 📊 Query Song Information

Get complete song details including total earnings:

```clarity
(contract-call? .Royalty-Distribution-Engine get-song-info u1)
```

### 4. 👤 Check Collaborator Earnings

View individual collaborator statistics:

```clarity
(contract-call? .Royalty-Distribution-Engine get-collaborator-info u1 'SP1FQKN...)
```

## 🔧 Contract Functions

### Public Functions

| Function | Description | Parameters |
|----------|-------------|------------|
| `register-song` | 📝 Register new song with collaborators | song-id, title, collaborator-list |
| `distribute-royalty` | 💸 Distribute earnings to collaborators | song-id, amount, platform |
| `deactivate-song` | ⏸️ Temporarily disable song | song-id |
| `reactivate-song` | ▶️ Re-enable disabled song | song-id |
| `update-collaborator-percentage` | ✏️ Modify collaborator share | song-id, collaborator, new-percentage |

### Read-Only Functions

| Function | Description | Returns |
|----------|-------------|---------|
| `get-song-info` | 📋 Song details and earnings | Song data object |
| `get-collaborator-info` | 👤 Collaborator role and earnings | Collaborator data |
| `get-contract-stats` | 📈 Overall contract statistics | Total songs, royalties, status |
| `get-platform-earnings` | 🎵 Platform-specific earnings | Platform earnings data |
| `calculate-collaborator-share` | 🧮 Preview earnings calculation | Calculated share amount |

## 🏗️ Architecture

### Data Structures

- **Songs Map**: Stores song metadata, artist info, and total earnings
- **Collaborators Map**: Maps song-collaborator pairs to roles and percentages  
- **Platform Earnings**: Tracks total earnings per streaming platform
- **Earnings History**: Historical record of all distributions

### Key Constants

- `MAX-PERCENTAGE`: 10,000 (represents 100%)
- `CONTRACT-OWNER`: Deployer address with admin privileges
- Various error codes for different failure scenarios

## 🛡️ Security Features

- ✅ **Ownership Verification**: Only song artists can modify their songs
- ✅ **Percentage Validation**: Ensures splits always total exactly 100%
- ✅ **Emergency Pause**: Contract owner can pause in emergencies
- ✅ **Input Validation**: Comprehensive checks on all parameters
- ✅ **Immutable Records**: Transaction history cannot be altered

## 🧪 Testing

Run the test suite to verify contract functionality:

```bash
clarinet test
```

Tests cover:
- Song registration with various collaborator configurations
- Royalty distribution calculations
- Error handling for invalid inputs
- Access control and permissions

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch: `git checkout -b feature/amazing-feature`
3. Commit changes: `git commit -m 'Add amazing feature'`
4. Push to branch: `git push origin feature/amazing-feature`
5. Open a Pull Request

## 📜 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🌟 Roadmap

- [ ] Integration with major streaming platforms
- [ ] Mobile app for artists and collaborators
- [ ] Advanced analytics dashboard
- [ ] Multi-token support (beyond STX)
- [ ] Dispute resolution mechanisms

---

**Built with ❤️ on Stacks blockchain** 🚀
