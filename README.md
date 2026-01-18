# Secure DAG Ledger (Flutter)

A **Flutter-based Secure DAG (Directed Acyclic Graph) Ledger** demonstration that simulates how transactions can be stored, linked, and verified using DAG principles instead of a traditional blockchain.

This project is **educational** and helps understand:
- DAG-based transaction models (similar to IOTA / Tangle concepts)
- Cryptographic hashing (SHA-256)
- Parent–child relationships in DAGs
- Flutter state management for real-time updates

---

## 🚀 Features

- ✅ Genesis node creation
- ✅ Secure transaction hashing using SHA-256
- ✅ Tip selection mechanism (selects up to 2 parent nodes)
- ✅ Parent → child linking
- ✅ DAG integrity verification logic
- ✅ Search transactions by `txId`
- ✅ View all transactions in timestamp order
- ✅ Simple and clean Flutter UI

---

## 🧠 How It Works

### 1. Genesis Node
- The DAG starts with a fixed **GENESIS_NODE**
- All first transactions reference the genesis node

### 2. Adding Transactions
- Each transaction:
  - Contains data and timestamp
  - Selects up to **2 tips** (nodes without children)
  - Generates a unique `txId` using SHA-256 hashing

### 3. DAG Structure
- Each node stores:
  - Parents (incoming edges)
  - Children (outgoing edges)
- No cycles are allowed → maintains **Directed Acyclic Graph**

### 4. Security
- `txId` is derived from:
