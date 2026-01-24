import {
    makeContractCall,
    broadcastTransaction,
    AnchorMode,
    PostConditionMode,
    stringAsciiCV,
    principalCV,
    callReadOnlyFunction,
    cvToValue
} from '@stacks/transactions';
import { stacksConfig, CONTRACT_ADDRESS, CONTRACT_NAME } from './config';

export class ChainRegistryContract {
    private userSession: any;

    constructor(userSession: any) {
        this.userSession = userSession;
    }

    async registerName(name: string): Promise<string> {
        const userData = this.userSession.loadUserData();

        const txOptions = {
            contractAddress: CONTRACT_ADDRESS,
            contractName: CONTRACT_NAME,
            functionName: 'register-name',
            functionArgs: [stringAsciiCV(name)],
            senderKey: userData.appPrivateKey,
            network: stacksConfig.network,
            anchorMode: AnchorMode.Any,
            postConditionMode: PostConditionMode.Allow
        };

        const transaction = await makeContractCall(txOptions);
        const broadcastResponse = await broadcastTransaction(transaction, stacksConfig.network);

        return broadcastResponse.txid;
    }

    async transferName(name: string, newOwner: string): Promise<string> {
        const userData = this.userSession.loadUserData();

        const txOptions = {
            contractAddress: CONTRACT_ADDRESS,
            contractName: CONTRACT_NAME,
            functionName: 'transfer-name',
            functionArgs: [stringAsciiCV(name), principalCV(newOwner)],
            senderKey: userData.appPrivateKey,
            network: stacksConfig.network,
            anchorMode: AnchorMode.Any,
            postConditionMode: PostConditionMode.Allow
        };

        const transaction = await makeContractCall(txOptions);
        const broadcastResponse = await broadcastTransaction(transaction, stacksConfig.network);

        return broadcastResponse.txid;
    }

    async releaseName(name: string): Promise<string> {
        const userData = this.userSession.loadUserData();

        const txOptions = {
            contractAddress: CONTRACT_ADDRESS,
            contractName: CONTRACT_NAME,
            functionName: 'release-name',
            functionArgs: [stringAsciiCV(name)],
            senderKey: userData.appPrivateKey,
            network: stacksConfig.network,
            anchorMode: AnchorMode.Any,
            postConditionMode: PostConditionMode.Allow
        };

        const transaction = await makeContractCall(txOptions);
        const broadcastResponse = await broadcastTransaction(transaction, stacksConfig.network);

        return broadcastResponse.txid;
    }

    async isNameAvailable(name: string): Promise<boolean> {
        const options = {
            contractAddress: CONTRACT_ADDRESS,
            contractName: CONTRACT_NAME,
            functionName: 'is-name-available',
            functionArgs: [stringAsciiCV(name)],
            network: stacksConfig.network,
            senderAddress: CONTRACT_ADDRESS
        };

        const result = await callReadOnlyFunction(options);
        return cvToValue(result);
    }

    async getNameOwner(name: string): Promise<string | null> {
        const options = {
            contractAddress: CONTRACT_ADDRESS,
            contractName: CONTRACT_NAME,
            functionName: 'get-name-owner',
            functionArgs: [stringAsciiCV(name)],
            network: stacksConfig.network,
            senderAddress: CONTRACT_ADDRESS
        };

        const result = await callReadOnlyFunction(options);
        const value = cvToValue(result);
        return value || null;
    }

    async getRegistration(name: string): Promise<{ owner: string; registeredAt: number } | null> {
        const options = {
            contractAddress: CONTRACT_ADDRESS,
            contractName: CONTRACT_NAME,
            functionName: 'get-registration',
            functionArgs: [stringAsciiCV(name)],
            network: stacksConfig.network,
            senderAddress: CONTRACT_ADDRESS
        };

        const result = await callReadOnlyFunction(options);
        const value = cvToValue(result);

        if (!value) return null;

        return {
            owner: value.owner,
            registeredAt: Number(value['registered-at'])
        };
    }
}
