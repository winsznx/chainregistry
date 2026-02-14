
import { createPublicClient, http, ContractFunctionExecutionError } from 'viem';
import { mainnet } from 'viem/chains';

export class BaseContractAdapter {
    private client;
    private address: `0x${string}`;

    constructor(address: `0x${string}`) {
        this.address = address;
        this.client = createPublicClient({
            chain: mainnet,
            transport: http()
        });
    }

    async retryCall<T>(fn: () => Promise<T>, retries = 3): Promise<T> {
        try {
            return await fn();
        } catch (error) {
            if (retries > 0 && error instanceof ContractFunctionExecutionError) {
                await new Promise(r => setTimeout(r, 1000));
                return this.retryCall(fn, retries - 1);
            }
            throw error;
        }
    }

    async readState(functionName: string, args: any[] = []) {
        return this.retryCall(() => this.client.readContract({
            address: this.address,
            abi: [], // TODO: Import ABI
            functionName,
            args
        }));
    }
}
