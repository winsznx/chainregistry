import { Clarinet, Tx, Chain, Account, types } from 'https://deno.land/x/clarinet@v1.5.4/index.ts';
import { assertEquals } from 'https://deno.land/std@0.170.0/testing/asserts.ts';

Clarinet.test({
    name: "Can register a new name",
    async fn(chain: Chain, accounts: Map<string, Account>) {
        const deployer = accounts.get('deployer')!;
        const wallet1 = accounts.get('wallet_1')!;

        let block = chain.mineBlock([
            Tx.contractCall(
                'chain-registry',
                'register-name',
                [types.ascii("alice")],
                wallet1.address
            )
        ]);

        block.receipts[0].result.expectOk().expectBool(true);

        // Verify ownership
        let checkBlock = chain.mineBlock([
            Tx.contractCall(
                'chain-registry',
                'get-name-owner',
                [types.ascii("alice")],
                deployer.address
            )
        ]);

        checkBlock.receipts[0].result.expectSome().expectPrincipal(wallet1.address);
    },
});

Clarinet.test({
    name: "Cannot register duplicate name",
    async fn(chain: Chain, accounts: Map<string, Account>) {
        const wallet1 = accounts.get('wallet_1')!;
        const wallet2 = accounts.get('wallet_2')!;

        let block = chain.mineBlock([
            Tx.contractCall(
                'chain-registry',
                'register-name',
                [types.ascii("alice")],
                wallet1.address
            ),
            Tx.contractCall(
                'chain-registry',
                'register-name',
                [types.ascii("alice")],
                wallet2.address
            )
        ]);

        block.receipts[0].result.expectOk();
        block.receipts[1].result.expectErr().expectUint(100); // ERR-NAME-TAKEN
    },
});

Clarinet.test({
    name: "Can transfer name ownership",
    async fn(chain: Chain, accounts: Map<string, Account>) {
        const deployer = accounts.get('deployer')!;
        const wallet1 = accounts.get('wallet_1')!;
        const wallet2 = accounts.get('wallet_2')!;

        let block = chain.mineBlock([
            Tx.contractCall(
                'chain-registry',
                'register-name',
                [types.ascii("alice")],
                wallet1.address
            ),
            Tx.contractCall(
                'chain-registry',
                'transfer-name',
                [types.ascii("alice"), types.principal(wallet2.address)],
                wallet1.address
            )
        ]);

        block.receipts[1].result.expectOk().expectBool(true);

        // Verify new ownership
        let checkBlock = chain.mineBlock([
            Tx.contractCall(
                'chain-registry',
                'get-name-owner',
                [types.ascii("alice")],
                deployer.address
            )
        ]);

        checkBlock.receipts[0].result.expectSome().expectPrincipal(wallet2.address);
    },
});

Clarinet.test({
    name: "Can release a name",
    async fn(chain: Chain, accounts: Map<string, Account>) {
        const deployer = accounts.get('deployer')!;
        const wallet1 = accounts.get('wallet_1')!;

        let block = chain.mineBlock([
            Tx.contractCall(
                'chain-registry',
                'register-name',
                [types.ascii("alice")],
                wallet1.address
            ),
            Tx.contractCall(
                'chain-registry',
                'release-name',
                [types.ascii("alice")],
                wallet1.address
            )
        ]);

        block.receipts[1].result.expectOk().expectBool(true);

        // Verify name is available again
        let checkBlock = chain.mineBlock([
            Tx.contractCall(
                'chain-registry',
                'is-name-available',
                [types.ascii("alice")],
                deployer.address
            )
        ]);

        checkBlock.receipts[0].result.expectBool(true);
    },
});
