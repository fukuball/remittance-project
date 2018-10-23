const Web3 = require('web3');
const web3 = new Web3();
const Ganache = require('ganache-cli');
web3.setProvider(Ganache.provider());
const Promise = require('bluebird');
Promise.promisifyAll(web3.eth, { suffix: "Promise" });
Promise.promisifyAll(web3.version, { suffix: "Promise" });
const assert = require('assert-plus');
const truffleContract = require("truffle-contract");

const HelloWorld = truffleContract(require(__dirname + "/../build/contracts/HelloWorld.json"));
HelloWorld.setProvider(web3.currentProvider);

describe("HelloWorld", function() {
    let accounts, originalOwner, networkId, helloWorldContract;
    const PHRASE = "Hello World";

    before("get accounts", function() {
        return web3.eth.getAccountsPromise()
            .then(_accounts => {
                accounts = _accounts;
                originalOwner = accounts[0];
            })
            .then(() => web3.version.getNetworkPromise())
            .then(_networkId => {
                networkId = _networkId;
                HelloWorld.setNetwork(networkId);
            });
    });

    beforeEach("deploy a HelloWorld", function() {
        return HelloWorld.new({ from: originalOwner, gas: 3000000 })
            .then(_helloWorld => helloWorldContract = _helloWorld);
    });

    it('should say hello', async function() {
        const sayHello = await helloWorldContract.sayHello({from: originalOwner});
        assert.strictEqual(sayHello, PHRASE);
    });
});