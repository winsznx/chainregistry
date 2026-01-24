import { createAppKit } from '@reown/appkit';
import { EthersAdapter } from '@reown/appkit-adapter-ethers';
import { baseConfig } from './config';

export class BaseWallet {
    private appKit: any;

    constructor() {
        this.appKit = createAppKit({
            adapters: [new EthersAdapter()],
            ...baseConfig
        });
    }

    async connect() {
        await this.appKit.open();
    }

    async disconnect() {
        await this.appKit.disconnect();
    }

    getAddress(): string | null {
        return this.appKit.getAddress();
    }

    getNetwork(): string | null {
        const chainId = this.appKit.getChainId();
        return chainId ? `Chain ID: ${chainId}` : null;
    }

    async getBalance(): Promise<string | null> {
        const provider = this.appKit.getWalletProvider();
        if (!provider) return null;

        try {
            const address = this.getAddress();
            if (!address) return null;

            const balance = await provider.getBalance(address);
            return (Number(balance) / 1e18).toFixed(4);
        } catch (error) {
            console.error('Error fetching balance:', error);
            return null;
        }
    }

    isConnected(): boolean {
        return this.appKit.getIsConnected();
    }

    getProvider() {
        return this.appKit.getWalletProvider();
    }
}
