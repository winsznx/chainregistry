import { base, baseSepolia } from '@reown/appkit/networks';

export const baseConfig = {
    projectId: process.env.NEXT_PUBLIC_REOWN_PROJECT_ID || '',
    networks: [base, baseSepolia],
    defaultNetwork: baseSepolia,
    metadata: {
        name: 'ChainRegistry',
        description: 'Decentralized username registry',
        url: 'https://chainregistry.app',
        icons: ['https://chainregistry.app/icon.png']
    }
};

export const CONTRACT_ADDRESSES = {
    [base.id]: '0x0000000000000000000000000000000000000000', // Replace after deployment
    [baseSepolia.id]: '0x0000000000000000000000000000000000000000' // Replace after deployment
};
