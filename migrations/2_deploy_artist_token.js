var ArtistTokenContract = artifacts.require("ArtistTokenContract");

module.exports = function(deployer){
  deployer.deploy(ArtistTokenContract);
};
