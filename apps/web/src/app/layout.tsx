import type { Metadata } from 'next';
import './globals.css';

export const metadata: Metadata = {
    title: 'ChainRegistry - Decentralized Username Registry',
    description: 'Register and manage unique usernames on Base and Stacks blockchains',
    keywords: ['blockchain', 'registry', 'username', 'base', 'stacks', 'web3'],
};

export default function RootLayout({
    children,
}: {
    children: React.ReactNode;
}) {
    return (
        <html lang="en">
            <body>{children}</body>
        </html>
    );
}
