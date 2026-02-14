
import React from 'react';
import { Button } from '@repo/shared/components/Button';

export default function Page() {
  return (
    <main className="min-h-screen flex flex-col items-center justify-center p-24 bg-gradient-to-b from-slate-50 to-white dark:from-zinc-900 dark:to-zinc-950">
      <div className="z-10 max-w-5xl w-full items-center justify-between font-mono text-sm lg:flex">
        <h1 className="text-4xl font-bold tracking-tighter sm:text-5xl text-slate-600 dark:text-slate-400">
          Chainregistry
        </h1>
        <div className="fixed bottom-0 left-0 flex h-48 w-full items-end justify-center bg-gradient-to-t from-white via-white dark:from-black dark:via-black lg:static lg:h-auto lg:w-auto lg:bg-none">
          <Button variant="primary" size="lg">Connect Wallet</Button>
        </div>
      </div>
      
      <div className="mt-12 grid grid-cols-1 gap-4 sm:grid-cols-2 lg:grid-cols-3">
        {"Dashboard,Transactions,Settings".split(',').map((item) => (
            <div key={item} className="group rounded-lg border border-transparent px-5 py-4 transition-colors hover:border-slate-300 hover:bg-slate-100/10 hover:dark:border-neutral-700 hover:dark:bg-neutral-800/30">
              <h2 className="mb-3 text-2xl font-semibold">{item} -></h2>
              <p className="m-0 max-w-[30ch] text-sm opacity-50">
                Manage your {item.toLowerCase()} securely on-chain.
              </p>
            </div>
        ))}
      </div>
    </main>
  );
}
