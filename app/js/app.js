const Web3 = require("web3");
const Promise = require("bluebird");
const truffleContract = require("truffle-contract");
const $ = require("jquery");
// Not to forget our built contract
const helloWorldJson = require("../../build/contracts/HelloWorld.json");

// Supports Mist, and other wallets that provide 'web3'.
if (typeof web3 !== 'undefined') {
    // Use the Mist/wallet/Metamask provider.
    window.web3 = new Web3(web3.currentProvider);
} else {
    // Your preferred fallback.
    window.web3 = new Web3(new Web3.providers.HttpProvider('http://localhost:8545'));
}

Promise.promisifyAll(web3.eth, { suffix: "Promise" });
Promise.promisifyAll(web3.version, { suffix: "Promise" });

const helloWorldContract = truffleContract(helloWorldJson);
helloWorldContract.setProvider(web3.currentProvider);

const sayHello = function() {
    // Sometimes you have to force the gas amount to a value you know is enough because
    // `web3.eth.estimateGas` may get it wrong.
    const gas = 300000; let deployed;
    // We return the whole promise chain so that other parts of the UI can be informed when
    // it is done.
    return helloWorldContract.deployed()
        .then(_deployed => {
            deployed = _deployed;
            // We simulate the real call and see whether this is likely to work.
            // No point in wasting gas if we have a likely failure.
            return _deployed.sayHello.call({ from: window.account, gas: gas });
        })
        .then(helloPhrase => alert(helloPhrase))
        .catch(e => {
            console.error(e);
        });
};

window.addEventListener('load', function() {
    return web3.eth.getAccountsPromise()
        .then(accounts => {
            if (accounts.length == 0) {
                throw new Error("No account with which to transact");
            }
            window.account = accounts[0];
            console.log(accounts[0]);
            return web3.version.getNetworkPromise();
        })
        .then(network => {
            console.log(network);
            return helloWorldContract.deployed();
        })
        .then(_deployed => {
            deployed = _deployed;
            console.log(deployed);
            return deployed;
        })
        // We wire it when the system looks in order.
        .then(() => $("#say-hello").click(sayHello))
        // Never let an error go unlogged.
        .catch(console.error);
});

require("file-loader?name=../index.html!../index.html");
