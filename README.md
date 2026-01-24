# ChainRegistry

Decentralized username/domain registry supporting Base (EVM) and Stacks blockchains.

## Features

- Register unique usernames on-chain (first-come-first-serve)
- Transfer ownership to other addresses
- Release names back to the registry
- Query name availability and ownership
- Multi-chain support (Base + Stacks)
- Clean black & white UI

## Tech Stack

### Frontend
- Next.js 14+ with TypeScript
- Tailwind CSS (black & white theme)
- pnpm workspaces monorepo

### Base (EVM)
- Solidity ^0.8.20
- Foundry for development and testing
- Reown (WalletConnect) for wallet connection
- ethers v6 for contract interaction

### Stacks
- Clarity v4 contracts
- Clarinet for development
- @stacks/connect for wallet connection
- @stacks/transactions for contract calls

## Project Structure

```
chainregistry/
├── apps/web/                    # Next.js frontend
├── contracts/
│   ├── base/                   # Solidity + Foundry
│   └── stacks/                 # Clarity v4 + Clarinet
├── packages/
│   ├── shared/                 # UI components & types
│   ├── base-adapter/           # Reown wallet integration
│   └── stacks-adapter/         # Stacks wallet integration
├── README.md
├── LICENSE
├── CONTRIBUTING.md
├── SECURITY.md
├── CODE_OF_CONDUCT.md
├── .env.example
├── .gitignore
└── pnpm-workspace.yaml
```

## Getting Started

### Prerequisites

- Node.js 18+
- pnpm 8+
- Foundry (for Base contracts)
- Clarinet (for Stacks contracts)

### Installation

```bash
# Install dependencies
pnpm install

# Install Foundry dependencies
cd contracts/base && forge install

# Run development server
pnpm dev
```

### Environment Variables

Copy `.env.example` to `.env` and fill in:

```env
NEXT_PUBLIC_REOWN_PROJECT_ID=your_reown_project_id
BASE_SEPOLIA_RPC_URL=your_base_sepolia_rpc
BASESCAN_API_KEY=your_basescan_key
PRIVATE_KEY=your_deployment_private_key
```

## Smart Contracts

### Base Contract

**ChainRegistry.sol** - Solidity contract with:
- `registerName(string name)` - Register a new name
- `transferName(string name, address newOwner)` - Transfer ownership
- `releaseName(string name)` - Release name back to registry
- `isNameAvailable(string name)` - Check availability
- `getNameOwner(string name)` - Get owner address
- `getRegistration(string name)` - Get full registration details

### Stacks Contract

**chain-registry.clar** - Clarity contract with:
- `(register-name (name (string-ascii 32)))` - Register name
- `(transfer-name (name (string-ascii 32)) (new-owner principal))` - Transfer
- `(release-name (name (string-ascii 32)))` - Release name
- `(is-name-available (name (string-ascii 32)))` - Check availability
- `(get-name-owner (name (string-ascii 32)))` - Get owner

## Development

### Test Base Contracts

```bash
cd contracts/base
forge test
```

### Test Stacks Contracts

```bash
cd contracts/stacks
clarinet test
```

### Deploy Base Contract

```bash
cd contracts/base
forge script script/Deploy.s.sol:DeployScript --rpc-url $BASE_SEPOLIA_RPC_URL --broadcast
```

### Deploy Stacks Contract

```bash
cd contracts/stacks
clarinet deploy --testnet
```

## Usage

1. **Connect Wallet**: Choose Base or Stacks and connect your wallet
2. **Register Name**: Enter a username (max 32 characters) and register
3. **Check Availability**: Search for names to see if they're available
4. **Transfer/Release**: Manage your registered names

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for contribution guidelines.

## Security

See [SECURITY.md](SECURITY.md) for security policy and vulnerability reporting.

## License

MIT License - see [LICENSE](LICENSE) for details.

## Links

- [Base Sepolia Explorer](https://sepolia.basescan.org/)
- [Stacks Testnet Explorer](https://explorer.hiro.so/?chain=testnet)
- [Reown Documentation](https://docs.reown.com/)
- [Stacks Documentation](https://docs.stacks.co/)
