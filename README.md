# NFT Marketplace Contract + Testing

![Solidity](https://img.shields.io/badge/Solidity-e6e6e6?style=for-the-badge&logo=solidity&logoColor=black) ![OpenZeppelin](https://img.shields.io/badge/OpenZeppelin-4E5EE4?logo=OpenZeppelin&logoColor=fff&style=for-the-badge) ![JavaScript](https://img.shields.io/badge/JavaScript-323330?style=for-the-badge&logo=javascript&logoColor=F7DF1E) 

## Main function
- `updateListingFee`: update listing fee of NFT
- `withdrawFunds`: withdraw ether from contract to owner
- `mintToken`: create a new NFT
- `createNftItem `: private helper function to create NFT Item
- `listNftItem`: set price and listing NFT 
- `updateItemPrice`: update price of NFT
- `unlistNftItem`: unlist NFT
- `buyNftItem`: buy and sell NFT
- `getTotalSupply`: get all NFT was minted from contract
- `getNFTItem`: get NFT Item from ID
- `getAllNFTItem`: get all NFTs is listing on the market
- `getUserNFT`: get all NFT of user

Try running some of the following tasks:
```shell
npx hardhat help
npx hardhat test
REPORT_GAS=true npx hardhat test
npx hardhat node
npx hardhat run scripts/deploy.js
