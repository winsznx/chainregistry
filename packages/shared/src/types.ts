
export interface ContractConfig {
    address: string;
    network: 'mainnet' | 'testnet';
    version: number;
}

export interface UserProfile {
    address: string;
    balance: string;
    nonce: number;
}

export type TransactionStatus = 'pending' | 'success' | 'failed';

export interface ApiResponse<T> {
    data?: T;
    error?: string;
    timestamp: number;
}
