// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

// INTERNAL IMPORT FOR NFT OPENZIPLINE
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import "hardhat/console.sol";

contract NFTMarketplace is ERC721URIStorage, Ownable {
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIds; // count total token 

    uint256 listingFee = 0.0015 ether; // price that user must pay to list NFT on market
    
    mapping(string => bool) private _usedTokenURI;
    mapping(uint256 => NftItem) private _idToNftItem;
    mapping(address => uint256) private _userNFTCount;
    struct NftItem {
        uint256 tokenId;
        address owner;
        address seller;
        uint256 price;
    }

    event NftItemCreated (uint256 indexed tokenId, address owner);
    event NftItemListed (uint256 indexed tokenId, address owner, uint256 price);
    event NftItemUnlisted (uint256 indexed tokenId, address seller);
    event NftItemUpdatePrice (uint256 indexed tokenId, address seller, uint256 price);
    event NftItemSold (uint256 indexed tokenId, address seller, address buyer, uint256 price);

    constructor() ERC721("NFT Metaverse Token", "MYNFT") {}

    // MODIFIER
    modifier minValue(uint256 _value) {
        require(_value > 0, "Input value must be at least 1 wei");
        _;
    }

    // FUNCTION

    // UPDATE & VIEW LISTING FEE
    function updateListingFee(uint256 _listingFee) public onlyOwner minValue(_listingFee){
        listingFee = _listingFee;
    }
    function getListingFee() public view returns(uint256) { // listingFee
        return listingFee;
    }
    function withdrawFunds(uint256 amount) public onlyOwner {
        uint256 contractBalance = address(this).balance;
        require(amount < contractBalance, "Insufficient balance to withdraw");
        address owner = owner();
        payable(owner).transfer(amount);
    }

    // MINT TOKEN: mint an ERC721 token and call createNftItem to create an NFT Item
    function mintToken(string calldata tokenURI) public returns(uint256) { // tokenId
        require(!_usedTokenURI[tokenURI], "tokenURI is exists");

        _tokenIds.increment();
        uint256 newTokenId = _tokenIds.current();

        _safeMint(msg.sender, newTokenId);
        _setTokenURI(newTokenId, tokenURI);
        _usedTokenURI[tokenURI] = true;

        uint256 count = _userNFTCount[msg.sender];
        count += 1;
        _userNFTCount[msg.sender] = count;

        createNftItem(newTokenId);
        return newTokenId;
    }
    // CREATE NFT ITEM: create an NFT item from ERC721 token and price (owner: , sold: false)
    function createNftItem(uint256 tokenId) private {
        _idToNftItem[tokenId] = NftItem(
            tokenId, 
            msg.sender, 
            address(0),
            0
        );

        emit NftItemCreated(tokenId, msg.sender);
    }
    // LIST NFT ITEM: 
    function listNftItem(uint256 tokenId, uint256 price) public payable minValue(price) {
        require(msg.value == listingFee, "Make sure ether attached == listing price");
        NftItem storage nftItem = _idToNftItem[tokenId];

        require(nftItem.owner == msg.sender, "Only NFT item owner can call this func");
        require(nftItem.seller == address(0), "NFT was listed");

        nftItem.price = price;
        nftItem.seller = msg.sender;
        nftItem.owner = address(this);

        transferFrom(msg.sender, address(this), tokenId); // transfer token to market
        emit NftItemListed(tokenId, msg.sender, price);
    }
    // UPDATE NFT ITEM PRICE
    function updateItemPrice(uint256 tokenId, uint256 price) public minValue(price) {
        NftItem storage nftItem = _idToNftItem[tokenId];
        require(nftItem.seller == msg.sender, "Only NFT item seller can call this func");
        nftItem.price = price;
        emit NftItemUpdatePrice(tokenId, msg.sender, price);
    }
    // UNLIST NFT ITEM
    function unlistNftItem(uint256 tokenId) public {
        NftItem storage nftItem = _idToNftItem[tokenId];
        require(nftItem.seller == msg.sender, "Only NFT item seller can call this func");
        require(nftItem.owner == address(this), "NFT is not listing");

        nftItem.owner = msg.sender;
        nftItem.seller = address(0);

        _transfer(address(this), msg.sender, tokenId); // transfer token to seller
        emit NftItemUnlisted(tokenId, msg.sender);
    }
    // BUY NFT: make a NFT-Item purchase
    function buyNftItem(uint256 tokenId) public payable {
        NftItem storage nftItem = _idToNftItem[tokenId];
        require(nftItem.owner == address(this), "NFT is not listing");
        require(msg.sender != address(this) && msg.sender != nftItem.seller, "Make sure buyer != owner & seller");
        require(msg.value == nftItem.price, "Make sure submit value == price");

        _transfer(address(this), msg.sender, tokenId);
        payable(nftItem.seller).transfer(msg.value); // payout NFT price for seller

        uint256 sellerCount = _userNFTCount[nftItem.seller];
        sellerCount -= 1;
        _userNFTCount[nftItem.seller] = sellerCount;

        uint256 buyerCount = _userNFTCount[msg.sender];
        buyerCount += 1;
        _userNFTCount[msg.sender] = buyerCount;
        
        emit NftItemSold(tokenId, nftItem.seller, msg.sender, nftItem.price);

        nftItem.owner = msg.sender;
        nftItem.seller = address(0);
    }

    // * function get data
    // GET_TOTAL_SUPPLY: get total NFT is minted
    function getTotalSupply() public view returns(uint256) {
        return _tokenIds.current();
    } 
    // GET_NFT_ITEM: get NFT Item by id
    function getNFTItem(uint256 tokenId) public view returns(NftItem memory){
        require(tokenId <= _tokenIds.current(), "Token id invalid");
        return _idToNftItem[tokenId];
    }
    // GET_ALL_NFT_ITEM: get all NFT item that are is listing
    function getAllNFTItem() public view returns(NftItem[] memory) {
        uint256 itemCount = _tokenIds.current();
        uint256 totalTokenList = balanceOf(address(this));
        uint256 currentIndex = 0;

        NftItem[] memory items = new NftItem[](totalTokenList);
        for (uint256 i = 1; i <= itemCount; i++) {
            if (_idToNftItem[i].owner == address(this)) {
                items[currentIndex] = _idToNftItem[i];
                currentIndex += 1;
            }
        }
        return items;
    }
    // GET_USER_NFT: get all NFT of user
    function getUserNFT(address userAddress) public view returns(NftItem[] memory) {
        uint256 totalCount = _tokenIds.current();
        uint256 totalNFTUser = _userNFTCount[userAddress];
        uint256 currentIndex = 0;

        NftItem[] memory items = new NftItem[](totalNFTUser);
        for (uint256 i = 1; i <= totalCount; i++) {
            if(_idToNftItem[i].owner == userAddress || _idToNftItem[i].seller == userAddress) {
                items[currentIndex] = _idToNftItem[i];
                currentIndex += 1;
            }
        }
        return items;
    }
}