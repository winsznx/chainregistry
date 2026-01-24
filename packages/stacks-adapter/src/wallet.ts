import { AppConfig, UserSession, showConnect } from '@stacks/connect';
import { stacksConfig } from './config';

export class StacksWallet {
    private appConfig: AppConfig;
    private userSession: UserSession;

    constructor() {
        this.appConfig = new AppConfig(['store_write', 'publish_data']);
        this.userSession = new UserSession({ appConfig: this.appConfig });
    }

    async connect() {
        showConnect({
            appDetails: {
                name: stacksConfig.appName,
                icon: stacksConfig.appIcon
            },
            onFinish: () => {
                window.location.reload();
            },
            userSession: this.userSession
        });
    }

    async disconnect() {
        this.userSession.signUserOut();
        window.location.reload();
    }

    getAddress(): string | null {
        if (!this.isConnected()) return null;
        const userData = this.userSession.loadUserData();
        return userData.profile.stxAddress.testnet;
    }

    getNetwork(): string {
        return stacksConfig.network.isMainnet() ? 'Mainnet' : 'Testnet';
    }

    async getBalance(): Promise<string | null> {
        const address = this.getAddress();
        if (!address) return null;

        try {
            const response = await fetch(
                `${stacksConfig.network.coreApiUrl}/extended/v1/address/${address}/balances`
            );
            const data = await response.json();
            return (Number(data.stx.balance) / 1e6).toFixed(2);
        } catch (error) {
            console.error('Error fetching balance:', error);
            return null;
        }
    }

    isConnected(): boolean {
        return this.userSession.isUserSignedIn();
    }

    getUserSession() {
        return this.userSession;
    }
}
