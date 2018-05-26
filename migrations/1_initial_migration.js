var Migrations = artifacts.require("./VXR.sol");

module.exports = function(deployer) {
  deployer.deploy(Migrations);
};
