const MultisigWallet = artifacts.require("MultisigWallet");

module.exports = function(deployer) {
  deployer.deploy(MultisigWallet);
};
