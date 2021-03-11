const MultisigWallet = artifacts.require("MultisigWallet");
const truffleAssert = require("truffle-assertions");

contract("MultisigWallet", async function(accounts){

  it("should deploy properly with added balance", async function(){
    let instance = await CoinFlip.deployed( { from:accounts[1],value: web3.utils.toWei(".1", "ether")}) ;
    assert(await web3.eth.getBalance(instance.address) == web3.utils.toWei(".1", "ether"), "balance not set");
  });
