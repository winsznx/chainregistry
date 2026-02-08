# Chainregistry

Decentralized username/domain registry with ownership transfer supporting Base (EVM) and Stacks blockchains.

## Features

- Unique smart contract logic for chainregistry
- Multi-chain support (Base + Stacks)
- Clean black & white UI
- Full wallet integration

## Tech Stack

### Frontend
- Next.js 14+ with TypeScript
- Tailwind CSS (black & white theme)
- pnpm workspaces monorepo

### Base (EVM)
- Solidity ^0.8.20
- Foundry for development
- Reown (WalletConnect) for wallet connection
- ethers v6 for contract interaction

### Stacks
- Clarity v4 contracts
- Clarinet for development
- @stacks/connect for wallet connection
- @stacks/transactions for contract calls

## Getting Started

```bash
# Install dependencies
pnpm install

# Run development server
pnpm dev
```

## License

MIT License - see [LICENSE](LICENSE) for details.
