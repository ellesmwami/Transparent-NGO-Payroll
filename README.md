# 🏢 Transparent NGO Payroll Smart Contract

> A blockchain-based payroll management system for Non-Governmental Organizations built on Stacks with complete transparency and accountability

## 📋 Overview

The Transparent NGO Payroll smart contract provides a decentralized solution for managing employee payroll in NGOs with full transparency. All transactions are recorded on-chain, enabling stakeholders to track fund allocation and employee payments.

## ✨ Features

- 👥 **Employee Management**: Add, update, and deactivate employees
- 💰 **Payroll Processing**: Automated salary distribution with payment verification
- 📊 **Transparency**: All payroll records stored on-chain for public verification
- 🗓️ **Payment Scheduling**: Configurable payroll frequency (default: 30 blocks)
- 💳 **Budget Management**: Monthly budget allocation and tracking
- 🔒 **Access Control**: Owner-only administrative functions
- 🚨 **Emergency Controls**: Emergency withdrawal functionality

## 🚀 Quick Start

### Prerequisites

- [Clarinet](https://docs.hiro.so/stacks/clarinet) installed
- [Node.js](https://nodejs.org/) for testing

### Installation

```bash
# Clone the repository
git clone <repository-url>
cd Transparent-NGO-Payroll

# Check contract syntax
clarinet check

# Install dependencies for testing
npm install

# Run tests
npm test
```

## 🛠️ Contract Functions

### Public Functions

#### 👤 Employee Management

**`add-employee`**
```clarity
(add-employee wallet name position salary)
```
Adds a new employee to the payroll system.
- `wallet`: Principal address of the employee
- `name`: Employee name (max 50 characters)
- `position`: Job position (max 50 characters)
- `salary`: Monthly salary in microSTX

**`update-employee-salary`**
```clarity
(update-employee-salary employee-id new-salary)
```
Updates an employee's salary.

**`deactivate-employee`**
```clarity
(deactivate-employee employee-id)
```
Deactivates an employee (stops future payments).

#### 💸 Payroll Operations

**`process-payroll`**
```clarity
(process-payroll employee-id)
```
Processes payment for a specific employee if payment is due.

**`fund-payroll`**
```clarity
(fund-payroll amount)
```
Adds STX tokens to the contract for payroll payments.

#### ⚙️ Configuration

**`set-organization-name`**
```clarity
(set-organization-name name)
```
Updates the organization name.

**`set-payroll-frequency`**
```clarity
(set-payroll-frequency frequency)
```
Sets the payroll frequency in blocks.

**`set-monthly-budget`**
```clarity
(set-monthly-budget month year amount)
```
Sets budget allocation for a specific month.

**`emergency-withdraw`**
```clarity
(emergency-withdraw)
```
⚠️ Emergency function to withdraw all contract funds (owner only).

### Read-Only Functions

**`get-employee`**
```clarity
(get-employee employee-id)
```
Returns employee details by ID.

**`get-employee-by-wallet`**
```clarity
(get-employee-by-wallet wallet)
```
Returns employee details by wallet address.

**`get-payroll-record`**
```clarity
(get-payroll-record payroll-id)
```
Returns specific payroll transaction record.

**`get-organization-info`**
```clarity
(get-organization-info)
```
Returns organization statistics and configuration.

**`get-contract-balance`**
```clarity
(get-contract-balance)
```
Returns current contract STX balance.

**`is-payment-due`**
```clarity
(is-payment-due employee-id)
```
Checks if payment is due for an employee.

**`get-monthly-budget`**
```clarity
(get-monthly-budget month year)
```
Returns budget information for a specific month.

## 📊 Usage Example

```bash
# Deploy the contract (in Clarinet console)
clarinet console

# Add an employee
(contract-call? .Transparent-NGO-Payroll add-employee 
  'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM 
  "John Doe" 
  "Program Manager" 
  u5000000)

# Fund the payroll
(contract-call? .Transparent-NGO-Payroll fund-payroll u50000000)

# Process payroll for employee
(contract-call? .Transparent-NGO-Payroll process-payroll u1)

# Check employee details
(contract-call? .Transparent-NGO-Payroll get-employee u1)
```

## 🔐 Security Features

- **Owner-only Functions**: Critical operations restricted to contract deployer
- **Input Validation**: All inputs are validated before processing
- **Payment Verification**: Ensures payments are only made when due
- **Balance Checks**: Prevents overdrafts and insufficient balance payments
- **Audit Trail**: Complete transaction history stored on-chain

## 📈 Error Codes

| Code | Error | Description |
|------|-------|-------------|
| u100 | `err-owner-only` | Function restricted to contract owner |
| u101 | `err-not-found` | Employee or record not found |
| u102 | `err-already-exists` | Employee already exists |
| u103 | `err-insufficient-balance` | Contract balance too low |
| u104 | `err-invalid-amount` | Invalid amount provided |
| u105 | `err-payment-not-due` | Payment not yet due |
| u106 | `err-already-paid` | Payment already processed |
| u107 | `err-unauthorized` | Unauthorized access |
| u108 | `err-invalid-date` | Invalid date parameters |

## 🧪 Testing

Run the test suite to verify contract functionality:

```bash
npm test
```

The test suite covers:
- Employee management operations
- Payroll processing
- Access control
- Error handling
- Edge cases


## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.


**Built with ❤️ for transparent NGO operations on Stacks blockchain**
