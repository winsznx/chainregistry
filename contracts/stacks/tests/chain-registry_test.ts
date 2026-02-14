
import { Clarinet, Tx, Chain, Account, types } from 'https://deno.land/x/clarinet@v1.4.2/index.ts';
import { assertEquals } from 'https://deno.land/std@0.170.0/testing/asserts.ts';

Clarinet.test({
    name: "Ensure that chainregistry follows ownership rules",
    async fn(chain: Chain, accounts: Map<string, Account>) {
        const deployer = accounts.get('deployer')!;
        const wallet1 = accounts.get('wallet_1')!;

        let block = chain.mineBlock([
            Tx.contractCall('chain-registry', 'get-owner', [], deployer.address)
        ]);
        
        assertEquals(block.receipts[0].result, `(ok ${deployer.address})`);
        assertEquals(block.height, 2);
    }
});
