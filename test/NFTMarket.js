const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("NFT Marketplace", () => {
  let nftMarketplace
  let signers

  before(async () => {
    const NFTMarketplace = await ethers.getContractFactory("NFTMarketplace")
    nftMarketplace = await NFTMarketplace.deploy()
    await nftMarketplace.deployed()
    signers = await ethers.getSigners()
  })

  const mint_nft = async (tokenURI) => {
    const transaction = await nftMarketplace.mintToken(tokenURI)
    const receipt = await transaction.wait()
    const tokenId = receipt.events[1].args.tokenId
    return tokenId
  }

  describe("Mint NFT", () => {
    it("Should do something", async () => {
      const tokenURI = "https://some-token1.uri/"
      const tokenId = await mint_nft(tokenURI)
      // Assert that the newly created NFT's token uri is the same one sent to the mint_nft
      const mintedTokenURI = await nftMarketplace.tokenURI(tokenId)
      expect(mintedTokenURI).to.equal(tokenURI)

      // Assert that the owner of the newly created NFT is the address that started the transaction
      const nftItem = await nftMarketplace.getNFTItem(tokenId)
      expect(nftItem.owner).to.equal(signers[0].address)
      expect(nftItem.price).to.equal(0)
      expect(nftItem.seller).to.equal(ethers.constants.AddressZero)
    })
  })

  describe("List NFT", () => {
    it("Should revert if price is zero", async () => {
      const tokenURI = "https://some-token2.uri/"
      const tokenId = await mint_nft(tokenURI)
      const transaction = nftMarketplace.listNftItem(tokenId, 0)
      await expect(transaction).to.be.revertedWith("Input value must be at least 1 wei")
    })
    it("Should revert if not attach ether equal listing fee", async () => {
      const tokenURI = "https://some-token3.uri/"
      const tokenId = await mint_nft(tokenURI)
      const transaction = nftMarketplace.listNftItem(tokenId, 1)
      await expect(transaction).to.be.revertedWith("Make sure ether attached == listing price")
    })
    it("Should revert if caller not owner", async () => {
      const tokenURI = "https://some-token4.uri/"
      const tokenId = await mint_nft(tokenURI)
      const transaction = nftMarketplace.connect(signers[1]).listNftItem(tokenId, 10, { value: ethers.utils.parseEther("0.0015") })
      await expect(transaction).to.be.revertedWith("Only NFT item owner can call this func")
    })
    it("Should list token if all requirements are met", async () => {
      const tokenURI = "https://some-token5.uri/"
      const tokenId = await mint_nft(tokenURI)
      const transaction = await nftMarketplace.listNftItem(tokenId, 10, { value: ethers.utils.parseEther("0.0015") })
      await transaction.wait()

      const nftItem = await nftMarketplace.getNFTItem(tokenId)
      expect(Number(nftItem.price)).to.equal(10)
      expect(nftItem.seller).to.equal(signers[0].address)
      expect(nftItem.owner).to.equal(nftMarketplace.address)
    })
  })

  describe("Update NFT", () => {
    it("Should revert if caller not seller when change price", async () => {
      const tokenURI = "https://some-token6.uri/"
      const tokenId = await mint_nft(tokenURI)
      const transaction = await nftMarketplace.listNftItem(tokenId, 10, { value: ethers.utils.parseEther("0.0015") })
      await transaction.wait()

      const transactionUpdate = nftMarketplace.connect(signers[1]).updateItemPrice(tokenId, 50)
      await expect(transactionUpdate).to.be.revertedWith("Only NFT item seller can call this func")
    })
    it("Should update price", async () => {
      const tokenURI = "https://some-token7.uri/"
      const tokenId = await mint_nft(tokenURI)
      const transaction = await nftMarketplace.listNftItem(tokenId, 10, { value: ethers.utils.parseEther("0.0015") })
      await transaction.wait()

      const transactionUpdate = await nftMarketplace.updateItemPrice(tokenId, 50)
      await transaction.wait()

      const nftItem = await nftMarketplace.getNFTItem(tokenId)
      expect(Number(nftItem.price)).to.equal(50)
    })
    it("Should revert if caller not seller when unlist NFT", async () => {
      const tokenURI = "https://some-token8.uri/"
      const tokenId = await mint_nft(tokenURI)
      const transaction = await nftMarketplace.listNftItem(tokenId, 10, { value: ethers.utils.parseEther("0.0015") })
      await transaction.wait()

      const transactionUpdate = nftMarketplace.connect(signers[1]).unlistNftItem(tokenId)
      await expect(transactionUpdate).to.be.revertedWith("Only NFT item seller can call this func")
    })
    it("Should unlist NFT success", async () => {
      const tokenURI = "https://some-token9.uri/"
      const tokenId = await mint_nft(tokenURI)
      const transaction = await nftMarketplace.listNftItem(tokenId, 10, { value: ethers.utils.parseEther("0.0015") })
      await transaction.wait()

      const transactionUpdate = await nftMarketplace.unlistNftItem(tokenId)
      await transactionUpdate.wait()

      const nftItem = await nftMarketplace.getNFTItem(tokenId)
      expect(Number(nftItem.price)).to.equal(10)
      expect(nftItem.seller).to.equal(ethers.constants.AddressZero)
      expect(nftItem.owner).to.equal(signers[0].address)
    })
  })

  describe("Buy NFT", () => {
    it("Should revert if NFT is not listed", async () => {
      const tokenURI = "https://some-token10.uri/"
      const tokenId = await mint_nft(tokenURI)
      const transaction = nftMarketplace.buyNftItem(tokenId)
      await expect(transaction).to.be.revertedWith("NFT is not listing")
    })
    it("Should revert if caller is seller", async () => {
      const tokenURI = "https://some-token11.uri/"
      const tokenId = await mint_nft(tokenURI)
      const transaction = await nftMarketplace.listNftItem(tokenId, 10, { value: ethers.utils.parseEther("0.0015") })
      await transaction.wait()

      const transactionBuy = nftMarketplace.connect(signers[0]).buyNftItem(tokenId)
      await expect(transactionBuy).to.be.revertedWith("Make sure buyer != owner & seller")
    })
    it("Should revert if the buyer doesn't attach enough ether to buy NFT", async () => {
      const tokenURI = "https://some-token12.uri/"
      const tokenId = await mint_nft(tokenURI)
      const transaction = await nftMarketplace.listNftItem(tokenId, 10, { value: ethers.utils.parseEther("0.0015") })
      await transaction.wait()

      const transactionBuy = nftMarketplace.connect(signers[2]).buyNftItem(tokenId)
      await expect(transactionBuy).to.be.revertedWith("Make sure submit value == price")
    })
    it("Should buy NFT success if all requirements are met", async () => {
      const tokenURI = "https://some-token13.uri/"
      const tokenId = await mint_nft(tokenURI)
      const transaction = await nftMarketplace.listNftItem(tokenId, 100000000000000, { value: ethers.utils.parseEther("0.0015") })
      await transaction.wait()

      await new Promise(r => setTimeout(r, 100))
      const oldSellerBalance = await signers[0].getBalance()

      const transactionBuy = await nftMarketplace.connect(signers[2]).buyNftItem(tokenId, { value: ethers.utils.parseEther("0.0001") })
      await transactionBuy.wait()

      await new Promise(r => setTimeout(r, 100))
      const newSellerBalance = await signers[0].getBalance()

      const diff = newSellerBalance.sub(oldSellerBalance);
      expect(diff).to.equal(100000000000000)

      const nftItem = await nftMarketplace.getNFTItem(tokenId)
      expect(Number(nftItem.price)).to.equal(100000000000000)
      expect(nftItem.seller).to.equal("0x0000000000000000000000000000000000000000")
      expect(nftItem.owner).to.equal(signers[2].address)

    })
  })

  describe("Fetch NFT", () => {
    it("Check total supply", async () => {
      const total = await nftMarketplace.getTotalSupply()
      expect(Number(total)).to.equal(13)
    })
    it("Check total NFT listing", async () => {
      const nftArr = await nftMarketplace.getAllNFTItem()
      expect(nftArr.length).to.equal(6)
    })
    it("Check My NFT", async () => {
      const nftArr = await nftMarketplace.connect(signers[2]).getMyNFT()
      expect(nftArr.length).to.equal(1)
    })
  })

  describe("Withdraw", () => {
    it("Should revert if caller not contract owner", async () => {
      const transaction = nftMarketplace.connect(signers[1]).withdrawFunds(100)
      await expect(transaction).to.be.revertedWith("Ownable: caller is not the owner")
    })
    it("Should revert if contract balance not enought", async () => {
      const transaction = nftMarketplace.connect(signers[0]).withdrawFunds(13000000000000000n)
      await expect(transaction).to.be.revertedWith("Insufficient balance to withdraw")
    })
    it("Should withdraw success", async () => {
      const oldContractBalance = await nftMarketplace.provider.getBalance(nftMarketplace.address)
      const oldOwnerBalance = await signers[0].getBalance()

      const transaction = await nftMarketplace.connect(signers[0]).withdrawFunds(2000000000000000n)
      const recepit = await transaction.wait()
      const gasFee = recepit.gasUsed.mul(recepit.effectiveGasPrice)

      const newContractBalance = await nftMarketplace.provider.getBalance(nftMarketplace.address)
      const newOwnerBalance = await signers[0].getBalance()

      const diffContract = oldContractBalance.sub(newContractBalance);
      const diffOwner = newOwnerBalance.sub(oldOwnerBalance).add(gasFee);

      expect(diffContract).to.equal(diffOwner)
    })
  })
})