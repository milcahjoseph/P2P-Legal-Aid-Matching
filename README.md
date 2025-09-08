# ⚖️ P2P Legal Aid Matching Platform

A decentralized platform connecting lawyers with low-income clients using Stacks blockchain and Clarity smart contracts.

## 🌟 Overview

This platform enables verified low-income individuals to access legal aid by matching them with qualified lawyers. The system uses token incentives to encourage participation and maintains quality through a reputation-based review system.

## ✨ Features

- 👥 **User Registration**: Separate registration for clients and lawyers
- 🔍 **Income Verification**: Ensures only qualified low-income users access services  
- 📋 **Case Management**: Create, apply to, and manage legal cases
- 🤝 **Smart Matching**: Clients can review lawyer applications and select representation
- 🏆 **Token Rewards**: Earn tokens for case completion and reviews
- ⭐ **Reputation System**: Build trust through ratings and feedback
- 💰 **Token Withdrawal**: Convert earned tokens to real value

## 🚀 Getting Started

### Prerequisites
- Clarinet CLI installed
- Stacks wallet configured

### Installation
```bash
git clone <repository-url>
cd P2P-Legal-Aid-Matching
clarinet console
```

## 📖 Usage Guide

### For Clients 👤

1. **Register as Client**
   ```clarity
   (contract-call? .p2p-legal-aid-matching register-user "client")
   ```

2. **Get Income Verified** (by platform admin)
   ```clarity
   (contract-call? .p2p-legal-aid-matching verify-income 'ST1... u40000)
   ```

3. **Create a Case**
   ```clarity
   (contract-call? .p2p-legal-aid-matching create-case 
     "Tenant Rights Issue" 
     "Need help with landlord dispute" 
     "Housing")
   ```

4. **Review Applications & Accept Lawyer**
   ```clarity
   (contract-call? .p2p-legal-aid-matching accept-lawyer u1 'ST2...)
   ```

5. **Complete Case & Submit Review**
   ```clarity
   (contract-call? .p2p-legal-aid-matching complete-case u1)
   (contract-call? .p2p-legal-aid-matching submit-review u1 u5 "Excellent service!")
   ```

### For Lawyers ⚖️

1. **Register as Lawyer**
   ```clarity
   (contract-call? .p2p-legal-aid-matching register-lawyer 
     "Family Law" 
     u150 
     "FL-123456")
   ```

2. **Apply to Cases**
   ```clarity
   (contract-call? .p2p-legal-aid-matching apply-to-case u1)
   ```

3. **Provide Legal Services** (off-chain)

4. **Submit Review After Case Completion**
   ```clarity
   (contract-call? .p2p-legal-aid-matching submit-review u1 u5 "Great client!")
   ```

## 🔍 Query Functions

- `get-user`: View user profile and stats
- `get-lawyer`: View lawyer details and availability  
- `get-case`: View case information and status
- `get-case-applications`: See all lawyer applications for a case
- `get-user-balance`: Check token balance
- `get-platform-stats`: View platform metrics

## 🎯 Token Economy

- 🎁 **New User Bonus**: 1000 tokens upon registration
- 💼 **Case Completion**: 1000 tokens for lawyers
- 📝 **Review Submission**: 100 tokens for both parties
- 🏅 **Reputation Points**: +10 per completed case

## 🛡️ Security Features

- Income verification by platform administrators
- Case status validation prevents unauthorized actions
- Duplicate prevention for applications and reviews
- Token balance verification for withdrawals

## 🏗️ Smart Contract Architecture

### Core Data Structures
- **Users**: Profile, reputation, earnings tracking
- **Lawyers**: Specialty, rates, availability, licensing
- **Cases**: Full case lifecycle management
- **Reviews**: Rating and feedback system
- **Tokens**: Internal reward mechanism

### Key Constants
- Minimum income threshold: $50,000
- Case completion reward: 1000 tokens
- Review reward: 100 tokens

## 🤝 Contributing

1. Fork the repository
2. Create feature branch (`git checkout -b feature/amazing-feature`)
3. Commit changes (`git commit -m 'Add amazing feature'`)
4. Push to branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## 📄 License

This project is open source and available under the MIT License.

## 🆘 Support

Need help? Create an issue in the repository or contact the development team.

---

*Built with ❤️ using Stacks blockchain and Clarity smart contracts*
