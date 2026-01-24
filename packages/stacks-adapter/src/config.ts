import { StacksMainnet, StacksTestnet } from '@stacks/network';

export const stacksConfig = {
    appName: 'ChainRegistry',
    appIcon: 'https://chainregistry.app/icon.png',
    network: new StacksTestnet(),
    mainnet: new StacksMainnet(),
    testnet: new StacksTestnet()
};

export const CONTRACT_ADDRESS = 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM'; // Replace after deployment
export const CONTRACT_NAME = 'chain-registry';
