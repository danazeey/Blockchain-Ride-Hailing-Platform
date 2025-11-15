# 🚗 Blockchain Ride-Hailing Platform

A decentralized ride-hailing platform built on Stacks blockchain that enables direct connections between drivers and riders with transparent pricing and no intermediaries.

## ✨ Features

- 🔐 **Smart Escrow System**: Secure payment handling with automatic release upon trip completion
- ⭐ **Rating Registry**: Two-way rating system for drivers and riders
- 💰 **Transparent Pricing**: Platform fee (5% default) visible to all participants
- 🚫 **No Intermediaries**: Direct peer-to-peer connections
- ✅ **Trip Management**: Complete lifecycle from request to completion
- 💸 **Automatic Payouts**: Instant driver payments upon trip completion

## 📋 Contract Overview

The smart contract manages:
- Driver and rider registration
- Trip creation and acceptance
- Escrow-based payment system
- Trip completion and fund distribution
- Bidirectional rating system
- Trip cancellation with automatic refunds

## 🚀 Getting Started

### Prerequisites

- [Clarinet](https://github.com/hirosystems/clarinet) installed
- Stacks wallet for testing

### Installation

```bash
git clone <your-repo-url>
cd Blockchain-Ride-Hailing-Platform
clarinet check
```

## 📖 Usage Guide

### For Riders 🙋

#### 1. Register as a Rider
```clarity
(contract-call? .Blockchain-Ride-Hailing-Platform register-rider)
```

#### 2. Request a Trip
```clarity
(contract-call? .Blockchain-Ride-Hailing-Platform 
    request-trip 
    "123 Main St" 
    "456 Oak Ave" 
    u1000000)
```
*Note: Fare is in microSTX (1 STX = 1,000,000 microSTX)*

#### 3. Rate Your Driver (After Trip Completion)
```clarity
(contract-call? .Blockchain-Ride-Hailing-Platform 
    rate-driver 
    u1 
    u5)
```
*Rating: 1-5 stars*

#### 4. Cancel a Trip (If Needed)
```clarity
(contract-call? .Blockchain-Ride-Hailing-Platform cancel-trip u1)
```

### For Drivers 🚕

#### 1. Register as a Driver
```clarity
(contract-call? .Blockchain-Ride-Hailing-Platform register-driver)
```

#### 2. Accept a Trip
```clarity
(contract-call? .Blockchain-Ride-Hailing-Platform accept-trip u1)
```

#### 3. Complete a Trip
```clarity
(contract-call? .Blockchain-Ride-Hailing-Platform complete-trip u1)
```
*This automatically transfers payment to the driver minus platform fee*

#### 4. Rate Your Rider (After Trip Completion)
```clarity
(contract-call? .Blockchain-Ride-Hailing-Platform 
    rate-rider 
    u1 
    u5)
```

### Read-Only Functions 📊

#### Check Driver Stats
```clarity
(contract-call? .Blockchain-Ride-Hailing-Platform get-driver 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM)
```

#### Check Rider Stats
```clarity
(contract-call? .Blockchain-Ride-Hailing-Platform get-rider 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM)
```

#### Get Trip Details
```clarity
(contract-call? .Blockchain-Ride-Hailing-Platform get-trip u1)
```

#### Get Driver Rating
```clarity
(contract-call? .Blockchain-Ride-Hailing-Platform get-driver-rating 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM)
```

#### Get Rider Rating
```clarity
(contract-call? .Blockchain-Ride-Hailing-Platform get-rider-rating 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM)
```

#### Calculate Fees
```clarity
(contract-call? .Blockchain-Ride-Hailing-Platform calculate-platform-fee u1000000)
(contract-call? .Blockchain-Ride-Hailing-Platform calculate-driver-payout u1000000)
```

## 🔄 Trip Lifecycle

```
1. 📝 REQUESTED  → Rider creates trip and deposits fare
2. ✅ ACCEPTED   → Driver accepts the trip
3. 🏁 COMPLETED  → Driver completes trip, receives payment (95%)
4. ⭐ RATED      → Both parties can rate each other
```

Or:

```
1. 📝 REQUESTED  → Rider creates trip
2. ❌ CANCELLED  → Either party cancels, rider gets full refund
```

## 💡 Key Concepts

### Trip Status Codes
- `u1` - Requested
- `u2` - Accepted
- `u3` - Completed
- `u4` - Cancelled

### Platform Fee
- Default: 5% of trip fare
- Configurable by contract owner (max 20%)
- Automatically deducted and sent to platform

### Rating System
- Scale: 1-5 stars
- Average rating calculated automatically
- Can only rate once per completed trip
- Both parties can rate each other

## 🔒 Security Features

- ✅ Escrow protection for riders
- ✅ Payment guaranteed for drivers upon completion
- ✅ No double-rating prevention
- ✅ Role-based access control
- ✅ Automatic refunds on cancellation
- ✅ Platform fee capped at 20%

## 🧪 Testing

Run the test suite:
```bash
clarinet test
```

Check contract syntax:
```bash
clarinet check
```

## 📊 Data Structures

### Driver Profile
- Registration status
- Total trips completed
- Rating sum and count
- Total earnings

### Rider Profile
- Registration status
- Total trips taken
- Rating sum and count
- Total amount spent

### Trip Record
- Rider and driver principals
- Fare amount
- Trip status
- Timestamps
- Pickup and destination locations
- Rating status for both parties

## 🛠️ Admin Functions

### Update Platform Fee
```clarity
(contract-call? .Blockchain-Ride-Hailing-Platform set-platform-fee u3)
```
*Only contract owner can execute*

## 📄 License

MIT

## 🤝 Contributing

Contributions welcome! Please open an issue or submit a pull request.

## 📞 Support

For issues or questions, please open a GitHub issue.

---

Built with ❤️ on Stacks Blockchain
