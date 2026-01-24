export type Chain = 'base' | 'stacks';

export type TransactionStatus = 'idle' | 'pending' | 'success' | 'error';

export interface WalletState {
    address: string | null;
    network: string | null;
    balance: string | null;
    isConnected: boolean;
}

export interface TransactionState {
    status: TransactionStatus;
    hash: string | null;
    error: string | null;
}

export interface Registration {
    name: string;
    owner: string;
    registeredAt: number;
}
