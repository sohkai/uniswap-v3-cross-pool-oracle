require('@nomiclabs/hardhat-ethers')

module.exports = {
  solidity: '0.7.6',
  networks: {
    hardhat: {},
    mainnet: {
      url: `https://mainnet.infura.io/v3/${process.env.INFURA_API_KEY}`,
    },
  },
}
