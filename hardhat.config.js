require('@nomiclabs/hardhat-ethers')
require("@nomiclabs/hardhat-etherscan");
require('hardhat-local-networks-config-plugin')

module.exports = {
  solidity: '0.7.6',
  networks: {
    hardhat: {},
    mainnet: {
      url: `https://mainnet.infura.io/v3/${process.env.INFURA_API_KEY}`,
    },
  },
  etherscan: {
    apiKey: process.env.ETHERSCAN_API_KEY,
  }
}
