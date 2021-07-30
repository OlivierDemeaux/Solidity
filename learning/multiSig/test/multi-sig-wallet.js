const { assert } = require("chai")
const chai = require("chai")
chai.use(require("chai-as-promised"))

const expect = chai.expect

const MultiSigWallet = artifacts.require("MultiSigWallet")

contract("MultiSigWallet", (accounts) => {
    const owners = [accounts[0], accounts[1], accounts[2]]
    const NUM_CONFIRMATIONS_REQUIRED = 2

    let wallet
    beforeEach(async () => {
        wallet = await MultiSigWallet.new(owners, NUM_CONFIRMATIONS_REQUIRED)
    })

    describe("check constructor", async () => {

        it("should deploy", async () => {
            const wallet = await MultiSigWallet.new(owners, NUM_CONFIRMATIONS_REQUIRED)

            for (let i = 0; i < owners.length; i++) {
                assert.equal(await wallet.owners(i), owners[i])
            }

            assert.equal(await wallet.numConfirmationsRequired(), NUM_CONFIRMATIONS_REQUIRED)
        })

        it("should reject if no owners", async () => {
            await expect(MultiSigWallet.new([], NUM_CONFIRMATIONS_REQUIRED)).to.be.rejected
        })

        it("should reject if nbConf > owners", async () => {
            await expect(MultiSigWallet.new(owners, owners.length + 1)).to.be.rejected
        })

        it("should reject if owner not unique", async () => {
            await expect(MultiSigWallet.new([owners[0], owners[0], owners[1]], NUM_CONFIRMATIONS_REQUIRED)).
            to.be.rejected
        })
    })

    describe("fallback", async () => {
        it("should receive ether", async () => {
            let balance = await web3.eth.getBalance(wallet.address)
            assert.equal(balance, 0)

            const { logs } = await wallet.sendTransaction({from: owners[0], value: 1})
            assert.equal(logs[0].event, "Deposit")
            assert.equal(logs[0].args.depositer, owners[0])
            assert.equal(logs[0].args.amount, 1)
            assert.equal(logs[0].args.balance, 1)
        })
    })

    describe("submit transaction", async () => {
        const to = owners[0]
        const value = 0
        const data = "0x00"

        it("should submit transaction", async () => {
            assert.equal(await wallet.getTransactionCount(), 0)

            const { logs } = await wallet.submitTransaction(to, value, data, {from: owners[0]})

            assert.equal(logs[0].event, "SubmitTransaction")
            assert.equal(logs[0].args.owner, owners[0])
            assert.equal(logs[0].args.txId, 0)
            assert.equal(logs[0].args.to, to)
            assert.equal(logs[0].args.value, value)
            assert.equal(logs[0].args.data, data)

            assert.equal(await wallet.getTransactionCount(), 1)

            const tx = await wallet.getTransaction(0)
            assert.equal(tx.to, to)
            assert.equal(tx.value, value)
            assert.equal(tx.data, data)
            assert.equal(tx.executed, false)
            assert.equal(tx.numConfirmations, 0)
        })

        it("should not let non owner submit tx", async () => {
            await expect(wallet.submitTransaction(to, value, data, {from: accounts[3]})).to.be.rejected
        })
    })

    describe("executeTransaction", () => {
        const to = owners[0]
        const value = 0
        const data = "0x00"

        beforeEach(async () => {
            await wallet.submitTransaction(to, value, data)
            await wallet.confirmTransaction(0, { from: owners[0] })
            await wallet.confirmTransaction(0, { from: owners[1] })
        })

        // execute transaction should succeed
        it("should execute", async () => {
            const { logs } = await wallet.executeTransaction(0, { from: owners[0] })

            assert.equal(logs[0].event, "ExecuteTransaction")
            assert.equal(logs[0].args.owner, owners[0])
            assert.equal(logs[0].args.txId, 0)

            const tx = await wallet.getTransaction(0)
            assert.equal(tx.executed, true)
        })

        // execute transaction should fail if already executed
        it("should reject if already executed", async () => {
            await wallet.executeTransaction(0, { from: owners[0] })

            await expect(wallet.executeTransaction(0, { from: owners[0] })).to.be.rejected
        })

        it("should reject if not owner", async () => {
            await expect(wallet.confirmTransaction(0, {from: accounts[3]})).to.be.rejected
        })

        it("should reject if non exciting tx", async () => {
            await expect(wallet.confirmTransaction(1, {from: accounts[0]})).to.be.rejected
        })
    })

    describe("fail to execute tx", () => {
        beforeEach(async () => {
            const to = owners[0]
            const value = 0
            const data = "0x00"

            await wallet.submitTransaction(to, value, data)
            await wallet.confirmTransaction(0, { from: owners[0] })
        })

        // execute transaction should fail
        it("should NOT execute", async () => {
            await expect(wallet.executeTransaction(0, { from: owners[0] })).to.be
            .rejected
        })

        // execute transaction should fail
        it("should NOT execute", async () => {
            await expect(wallet.executeTransaction(0, { from: owners[1] })).to.be
            .rejected
        })
    })

    describe("check what non-owner can do", () => {
        beforeEach(async () => {
            const to = owners[0]
            const value = 0
            const data = "0x00"

            await wallet.submitTransaction(to, value, data)
            await wallet.confirmTransaction(0, { from: owners[0] })
            await wallet.confirmTransaction(0, { from: owners[1] })
        })

        // execute transaction should fail
        it("should NOT confirm because not owner", async () => {
            await expect(wallet.confirmTransaction(0, { from: accounts[3] })).to.be
            .rejected
        })

         // execute transaction should fail
         it("should NOT execute because not owner", async () => {
            await expect(wallet.executeTransaction(0, { from: accounts[3] })).to.be
            .rejected
        })

         // execute transaction should succeed
         it("should execute", async () => {
            const res = await wallet.executeTransaction(0, { from: owners[2] })
            const { logs } = res

            assert.equal(logs[0].event, "ExecuteTransaction")
            assert.equal(logs[0].args.owner, owners[2])
            assert.equal(logs[0].args.txId, 0)

            const tx = await wallet.getTransaction(0)
            assert.equal(tx.executed, true)
        })
    })

    describe("getOwners", () => {
        it("should return the 3 owners", async() => {
            const res = await wallet.getOwners()
            assert.equal(res[0], owners[0])
            assert.equal(res[1], owners[1])
            assert.equal(res[2], owners[2])
        })
    })

    describe("getTransactionCount", () => {
        it("should return tx count", async () => {
            assert.equal(await wallet.getTransactionCount(), 0)
        })
    })

    describe("revoke confirmation", () => {
        beforeEach(async () => {
            const to = owners[0]
            const value = 0
            const data = "0x00"

            await wallet.submitTransaction(to, value, data)
            await wallet.confirmTransaction(0, { from: owners[0] })
            await wallet.confirmTransaction(0, { from: owners[1] })
        })

        it("tx should have 2 confirmations", async () => {
            const tx = await wallet.getTransaction(0)
            const numConf = tx[4].words[0]
            assert.equal(numConf, 2);

            const res = await wallet.isConfirmed(0, accounts[0])
            assert.equal(res, true)
        })

        it("shoul revoke conf from owners[0]", async () => {
            const { logs } = await wallet.revokeConfirmation(0, {from: owners[0]})
            assert.equal(logs[0].event, 'RevokeConfirmation')
            assert.equal(logs[0].args.owner, owners[0])
            assert.equal(logs[0].args.txId, 0)

            const tx = await wallet.getTransaction(0)
            assert.equal(tx.numConfirmations, 1);

            const response = await wallet.isConfirmed(0, accounts[0])
            assert.equal(response, false)
        })

        it("should reject revoke from non owner", async () => {
            await expect(wallet.revokeConfirmation(0, {from: accounts[4]})).to.be.rejected
        })

        it("should reject revoke for non exciting tx", async () => {
            await expect(wallet.revokeConfirmation(1, {from: accounts[0]})).to.be.rejected
        })
    })

})