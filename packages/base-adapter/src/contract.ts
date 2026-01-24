import { ethers } from 'ethers';
import { CONTRACT_ADDRESSES } from './config';

const ABI = [
    'function registerName(string calldata name) external',
    'function transferName(string calldata name, address newOwner) external',
    'function releaseName(string calldata name) external',
    'function isNameAvailable(string calldata name) external view returns (bool)',
    'function getNameOwner(string calldata name) external view returns (address)',
    'function getRegistration(string calldata name) external view returns (address owner, uint256 registeredAt)',
    'function getOwnerNames(address owner) external view returns (string[] memory)',
    'event NameRegistered(string indexed name, address indexed owner, uint256 timestamp)',
    'event NameTransferred(string indexed name, address indexed from, address indexed to)',
    'event NameReleased(string indexed name, address indexed owner)'
];

export class ChainRegistryContract {
    private contract: ethers.Contract | null = null;
    private provider: any;

    constructor(provider: any, chainId: number) {
        this.provider = provider;
        const contractAddress = CONTRACT_ADDRESSES[chainId];

        if (contractAddress && contractAddress !== '0x0000000000000000000000000000000000000000') {
            const signer = provider.getSigner();
            this.contract = new ethers.Contract(contractAddress, ABI, signer);
        }
    }

    async registerName(name: string): Promise<string> {
        if (!this.contract) throw new Error('Contract not initialized');

        const tx = await this.contract.registerName(name);
        await tx.wait();
        return tx.hash;
    }

    async transferName(name: string, newOwner: string): Promise<string> {
        if (!this.contract) throw new Error('Contract not initialized');

        const tx = await this.contract.transferName(name, newOwner);
        await tx.wait();
        return tx.hash;
    }

    async releaseName(name: string): Promise<string> {
        if (!this.contract) throw new Error('Contract not initialized');

        const tx = await this.contract.releaseName(name);
        await tx.wait();
        return tx.hash;
    }

    async isNameAvailable(name: string): Promise<boolean> {
        if (!this.contract) throw new Error('Contract not initialized');
        return await this.contract.isNameAvailable(name);
    }

    async getNameOwner(name: string): Promise<string> {
        if (!this.contract) throw new Error('Contract not initialized');
        return await this.contract.getNameOwner(name);
    }

    async getRegistration(name: string): Promise<{ owner: string; registeredAt: number }> {
        if (!this.contract) throw new Error('Contract not initialized');
        const [owner, registeredAt] = await this.contract.getRegistration(name);
        return { owner, registeredAt: Number(registeredAt) };
    }

    async getOwnerNames(owner: string): Promise<string[]> {
        if (!this.contract) throw new Error('Contract not initialized');
        return await this.contract.getOwnerNames(owner);
    }
}
