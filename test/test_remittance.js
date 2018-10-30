const expectedExceptionPromise = require("./expected_exception_testRPC_and_geth.js");
const Remittance = artifacts.require('Remittance');
const Promise = require("bluebird");
const BigNumber = web3.BigNumber;

Promise.promisifyAll(web3.eth, { suffix: "Promise" });

contract('Remittance', function(accounts) {
    const alice = accounts[0];
    const bob = accounts[1];
    const carol = accounts[2];
    let remittanceContract;

    beforeEach(function() {
      return Remittance.new({from: alice}).then(function(instance) {
        remittanceContract = instance;
      });
    });

    describe("send fund wire...", function() {

        const fundWireValueSet = [
            {   exchanger:                 carol,
                password1: "one-time-password-1",
                password2: "one-time-password-2",
                amount:                  "10240",
                blockDuration:              3000
            },
            {   exchanger:                 carol,
                password1: "one-time-password-3",
                password2: "one-time-password-4",
                amount:                  "20480",
                blockDuration:              3000
            },
        ];

        fundWireValueSet.forEach((values, index) => {
            it('should send wire fund on set ' + index, async function() {
                const txObj = await remittanceContract.sendFundWire(
                    carol,
                    values.password1,
                    values.password2,
                    values.blockDuration,
                    {
                        from: alice,
                        value: values.amount
                    });
                assert.strictEqual(txObj.receipt.logs.length, 1);
                assert.strictEqual(txObj.logs.length, 1);
                assert.strictEqual(txObj.logs[0].event, 'LogSendFundWire');
                assert.strictEqual(txObj.logs[0].args.sender, alice);
                assert.strictEqual(txObj.logs[0].args.exchanger, carol);
                //assert.strictEqual(txObj.logs[0].args.passwordHash, hash);
                assert.strictEqual(txObj.logs[0].args.amount.toString(10), values.amount);
                const contractEther = await web3.eth.getBalancePromise(remittanceContract.address);
                assert.strictEqual(contractEther.toString(10), values.amount);
            });
        });

    });
});