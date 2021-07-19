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

    describe("executeTransaction", () => {
        beforeEach(async () => {
            const to = owners[0]
            const value = 0
            const data = "0x00"

            await wallet.submitTransaction(to, value, data)
            await wallet.confirmTransaction(0, { from: owners[0] })
            await wallet.confirmTransaction(0, { from: owners[1] })
        })

        // execute transaction should succeed
        it("should execute", async () => {
            const res = await wallet.executeTransaction(0, { from: owners[0] })
            const { logs } = res

            assert.equal(logs[0].event, "ExecuteTransaction")
            assert.equal(logs[0].args.owner, owners[0])
            assert.equal(logs[0].args.txId, 0)

            const tx = await wallet.getTransaction(0)
            assert.equal(tx.executed, true)
        })

        // execute transaction should fail if already executed
        it("should reject if already executed", async () => {
            await wallet.executeTransaction(0, { from: owners[0] })

            /*
            try {
              await wallet.executeTransaction(0, { from: owners[0] })
              throw new Error("tx did not fail")
            } catch (error) {
              assert.equal(error.reason, "tx already executed")
            }
            */

            await expect(wallet.executeTransaction(0, { from: owners[0] })).to.be
            .rejected
        })
    })

    describe("fail to execute tx bacause not enough confirmations", () => {
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

    it("should return the 3 owners", async() => {
        const res = await wallet.getOwners()
        assert.equal(res[0], owners[0])
        assert.equal(res[1], owners[1])
        assert.equal(res[2], owners[2])
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
            const res = await wallet.revokeConfirmation(0, {from: owners[0]})
            const { logs } = res
            assert.equal(logs[0].event, 'RevokeConfirmation')
            assert.equal(logs[0].args.owner, owners[0])
            assert.equal(logs[0].args.txId, 0)

            const tx = await wallet.getTransaction(0)
            const numConf = tx[4].words[0]
            assert.equal(numConf, 1);

            const response = await wallet.isConfirmed(0, accounts[0])
            assert.equal(response, false)
        })
    })

})