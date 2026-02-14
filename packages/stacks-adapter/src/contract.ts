
import { StacksMainnet } from '@stacks/network';
import { callReadOnlyFunction, cvToJSON, standardPrincipalCV } from '@stacks/transactions';

export class StacksAdapter {
    private network;
    private contractAddress: string;
    private contractName: string;

    constructor(address: string, name: string) {
        this.network = new StacksMainnet();
        this.contractAddress = address;
        this.contractName = name;
    }

    async callReadOnly(functionName: string, args: any[] = []) {
        const options = {
            contractAddress: this.contractAddress,
            contractName: this.contractName,
            functionName,
            functionArgs: args,
            network: this.network,
            senderAddress: this.contractAddress,
        };

        try {
            const result = await callReadOnlyFunction(options);
            return cvToJSON(result);
        } catch (e) {
            console.error(f"Error calling {functionName}:", e);
            throw new Error(`Failed to call ${functionName}: ${e}`);
        }
    }
}
