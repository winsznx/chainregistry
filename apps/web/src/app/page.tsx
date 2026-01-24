'use client';

import { useState } from 'react';
import { Button, Card, Input } from '@chainregistry/shared';
import { BaseWallet, ChainRegistryContract as BaseContract } from '@chainregistry/base-adapter';
import { StacksWallet, ChainRegistryContract as StacksContract } from '@chainregistry/stacks-adapter';

type Chain = 'base' | 'stacks';
type TxStatus = 'idle' | 'pending' | 'success' | 'error';

export default function Home() {
    const [activeChain, setActiveChain] = useState<Chain>('base');
    const [name, setName] = useState('');
    const [searchName, setSearchName] = useState('');
    const [transferAddress, setTransferAddress] = useState('');

    // Wallet states
    const [baseWallet] = useState(() => new BaseWallet());
    const [stacksWallet] = useState(() => new StacksWallet());
    const [baseConnected, setBaseConnected] = useState(false);
    const [stacksConnected, setStacksConnected] = useState(false);
    const [baseAddress, setBaseAddress] = useState<string | null>(null);
    const [stacksAddress, setStacksAddress] = useState<string | null>(null);
    const [baseBalance, setBaseBalance] = useState<string | null>(null);
    const [stacksBalance, setStacksBalance] = useState<string | null>(null);

    // Transaction states
    const [txStatus, setTxStatus] = useState<TxStatus>('idle');
    const [txHash, setTxHash] = useState<string | null>(null);
    const [txError, setTxError] = useState<string | null>(null);

    // Query results
    const [isAvailable, setIsAvailable] = useState<boolean | null>(null);
    const [nameOwner, setNameOwner] = useState<string | null>(null);

    const connectBase = async () => {
        try {
            await baseWallet.connect();
            setBaseConnected(true);
            setBaseAddress(baseWallet.getAddress());
            setBaseBalance(await baseWallet.getBalance());
        } catch (error) {
            console.error('Base connection error:', error);
        }
    };

    const connectStacks = async () => {
        try {
            await stacksWallet.connect();
            setStacksConnected(true);
            setStacksAddress(stacksWallet.getAddress());
            setStacksBalance(await stacksWallet.getBalance());
        } catch (error) {
            console.error('Stacks connection error:', error);
        }
    };

    const registerName = async () => {
        if (!name) return;

        setTxStatus('pending');
        setTxHash(null);
        setTxError(null);

        try {
            if (activeChain === 'base') {
                const provider = baseWallet.getProvider();
                const chainId = provider.getChainId();
                const contract = new BaseContract(provider, chainId);
                const hash = await contract.registerName(name);
                setTxHash(hash);
                setTxStatus('success');
            } else {
                const userSession = stacksWallet.getUserSession();
                const contract = new StacksContract(userSession);
                const txid = await contract.registerName(name);
                setTxHash(txid);
                setTxStatus('success');
            }
        } catch (error: any) {
            setTxError(error.message || 'Transaction failed');
            setTxStatus('error');
        }
    };

    const checkAvailability = async () => {
        if (!searchName) return;

        try {
            if (activeChain === 'base') {
                const provider = baseWallet.getProvider();
                const chainId = provider.getChainId();
                const contract = new BaseContract(provider, chainId);
                const available = await contract.isNameAvailable(searchName);
                setIsAvailable(available);

                if (!available) {
                    const owner = await contract.getNameOwner(searchName);
                    setNameOwner(owner);
                } else {
                    setNameOwner(null);
                }
            } else {
                const userSession = stacksWallet.getUserSession();
                const contract = new StacksContract(userSession);
                const available = await contract.isNameAvailable(searchName);
                setIsAvailable(available);

                if (!available) {
                    const owner = await contract.getNameOwner(searchName);
                    setNameOwner(owner);
                } else {
                    setNameOwner(null);
                }
            }
        } catch (error) {
            console.error('Query error:', error);
        }
    };

    const getExplorerUrl = () => {
        if (!txHash) return '#';

        if (activeChain === 'base') {
            return `https://sepolia.basescan.org/tx/${txHash}`;
        } else {
            return `https://explorer.hiro.so/txid/${txHash}?chain=testnet`;
        }
    };

    const isConnected = activeChain === 'base' ? baseConnected : stacksConnected;
    const address = activeChain === 'base' ? baseAddress : stacksAddress;
    const balance = activeChain === 'base' ? baseBalance : stacksBalance;

    return (
        <main className="min-h-screen bg-white">
            {/* Header */}
            <header className="border-b-4 border-black bg-white">
                <div className="max-w-7xl mx-auto px-4 py-6">
                    <h1 className="text-4xl font-bold">ChainRegistry</h1>
                    <p className="text-gray-600 mt-2">Decentralized Username Registry</p>
                </div>
            </header>

            <div className="max-w-7xl mx-auto px-4 py-12">
                {/* Chain Selector */}
                <div className="flex gap-4 mb-8">
                    <Button
                        variant={activeChain === 'base' ? 'primary' : 'outline'}
                        onClick={() => setActiveChain('base')}
                    >
                        Base Network
                    </Button>
                    <Button
                        variant={activeChain === 'stacks' ? 'primary' : 'outline'}
                        onClick={() => setActiveChain('stacks')}
                    >
                        Stacks Network
                    </Button>
                </div>

                <div className="grid md:grid-cols-2 gap-8">
                    {/* Wallet Connection */}
                    <Card title="Wallet Connection">
                        {!isConnected ? (
                            <Button
                                onClick={activeChain === 'base' ? connectBase : connectStacks}
                                className="w-full"
                            >
                                Connect {activeChain === 'base' ? 'Base' : 'Stacks'} Wallet
                            </Button>
                        ) : (
                            <div className="space-y-4">
                                <div>
                                    <p className="text-sm text-gray-600">Address</p>
                                    <p className="font-mono text-sm break-all">{address}</p>
                                </div>
                                <div>
                                    <p className="text-sm text-gray-600">Network</p>
                                    <p className="font-medium">{activeChain === 'base' ? 'Base Sepolia' : 'Stacks Testnet'}</p>
                                </div>
                                <div>
                                    <p className="text-sm text-gray-600">Balance</p>
                                    <p className="font-medium">{balance} {activeChain === 'base' ? 'ETH' : 'STX'}</p>
                                </div>
                            </div>
                        )}
                    </Card>

                    {/* Register Name */}
                    <Card title="Register Name">
                        <div className="space-y-4">
                            <Input
                                label="Username"
                                placeholder="Enter username (max 32 chars)"
                                value={name}
                                onChange={(e) => setName(e.target.value)}
                                maxLength={32}
                            />
                            <Button
                                onClick={registerName}
                                disabled={!isConnected || !name || txStatus === 'pending'}
                                isLoading={txStatus === 'pending'}
                                className="w-full"
                            >
                                Register Name
                            </Button>

                            {txStatus === 'success' && txHash && (
                                <div className="p-4 bg-gray-100 border-2 border-black rounded">
                                    <p className="font-medium mb-2">Transaction Successful!</p>
                                    <a
                                        href={getExplorerUrl()}
                                        target="_blank"
                                        rel="noopener noreferrer"
                                        className="text-sm font-mono break-all underline"
                                    >
                                        {txHash}
                                    </a>
                                </div>
                            )}

                            {txStatus === 'error' && txError && (
                                <div className="p-4 bg-red-50 border-2 border-red-500 rounded">
                                    <p className="text-red-600">{txError}</p>
                                </div>
                            )}
                        </div>
                    </Card>

                    {/* Check Availability */}
                    <Card title="Check Availability">
                        <div className="space-y-4">
                            <Input
                                label="Search Username"
                                placeholder="Enter username to check"
                                value={searchName}
                                onChange={(e) => setSearchName(e.target.value)}
                                maxLength={32}
                            />
                            <Button
                                onClick={checkAvailability}
                                disabled={!isConnected || !searchName}
                                className="w-full"
                                variant="secondary"
                            >
                                Check Availability
                            </Button>

                            {isAvailable !== null && (
                                <div className={`p-4 border-2 rounded ${isAvailable ? 'bg-green-50 border-green-500' : 'bg-red-50 border-red-500'}`}>
                                    <p className="font-medium">
                                        {isAvailable ? 'Available!' : 'Already Registered'}
                                    </p>
                                    {nameOwner && (
                                        <p className="text-sm mt-2 font-mono break-all">
                                            Owner: {nameOwner}
                                        </p>
                                    )}
                                </div>
                            )}
                        </div>
                    </Card>

                    {/* Info */}
                    <Card title="How It Works">
                        <div className="space-y-3 text-sm">
                            <p>1. Connect your wallet for Base or Stacks</p>
                            <p>2. Register a unique username (first-come-first-serve)</p>
                            <p>3. Transfer ownership or release names</p>
                            <p>4. All registrations are permanent and immutable</p>
                            <p className="pt-4 text-gray-600">
                                Smart contracts are deployed on Base Sepolia and Stacks Testnet
                            </p>
                        </div>
                    </Card>
                </div>
            </div>

            {/* Footer */}
            <footer className="border-t-4 border-black mt-20 py-8">
                <div className="max-w-7xl mx-auto px-4 text-center text-gray-600">
                    <p>ChainRegistry - Multi-Chain Username Registry</p>
                    <p className="text-sm mt-2">MIT License - Open Source</p>
                </div>
            </footer>
        </main>
    );
}
