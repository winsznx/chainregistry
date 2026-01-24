# Security Policy

## Supported Versions

| Version | Supported          |
| ------- | ------------------ |
| 1.0.x   | :white_check_mark: |

## Reporting a Vulnerability

We take the security of ChainRegistry seriously. If you discover a security vulnerability, please follow these steps:

1. **Do Not** disclose the vulnerability publicly until it has been addressed
2. Email details to: timjosh507@gmail.com
3. Include:
   - Description of the vulnerability
   - Steps to reproduce
   - Potential impact
   - Suggested fix (if any)

## Response Timeline

- **Initial Response**: Within 48 hours
- **Status Update**: Within 7 days
- **Fix Timeline**: Depends on severity (critical issues within 7 days)

## Security Best Practices

### Smart Contracts
- All contracts are immutable after deployment
- Use only audited wallet providers (Reown, Stacks Connect)
- Never share private keys or seed phrases
- Verify contract addresses before interaction

### Frontend
- Always verify transaction details before signing
- Check network before submitting transactions
- Use hardware wallets for high-value operations

## Disclosure Policy

Once a vulnerability is fixed:
1. We will publish a security advisory
2. Credit will be given to the reporter (unless anonymity is requested)
3. A patch release will be published

## Known Limitations

- Smart contracts cannot be upgraded after deployment
- Users are responsible for their own private key security
- Transaction fees are paid by users

## Contact

For security concerns: timjosh507@gmail.com
