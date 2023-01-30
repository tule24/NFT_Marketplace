// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

// INTERNAL IMPORT FOR NFT OPENZIPLINE
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

import "hardhat/console.sol";

// Listing NFT
// Mint NFT
// Buy/Sell NFT
contract NFTMarketplace is ERC721URIStorage {
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIds; // count total token 
    Counters.Counter private _itemsListed; // count item listing

    uint256 listingFee; // price that user must pay to list NFT on market
    address payable owner;
    
    mapping(string => bool) private _usedTokenURI;
    mapping(uint256 => NftItem) private _idToNftItem;
    struct NftItem {
        uint256 tokenId;
        address payable owner;
        uint256 price;
        bool isListed;
    }

    event NftItemCreated (uint256 indexed tokenId, address owner);
    event NftItemListed (uint256 indexed tokenId, address owner, uint256 price);

    constructor(uint256 _listingFee) ERC721("NFT Metaverse Token", "MYNFT") {
        owner == payable(msg.sender);
        listingFee = _listingFee;
    }

    // MODIFIER
    modifier onlyOwner() {
        require(msg.sender == owner, "only owner can call this function");
        _;
    }
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

    // MINT TOKEN: mint an ERC721 token and call createNftItem to create an NFT Item
    function mintToken(string memory tokenURI) public returns(uint256) { // tokenId
        require(!_usedTokenURI[tokenURI], "tokenURI is exists");

        _tokenIds.increment();
        uint256 newTokenId = _tokenIds.current();

        _mint(msg.sender, newTokenId);
        _setTokenURI(newTokenId, tokenURI);
        _usedTokenURI[tokenURI] = true;

        createNftItem(newTokenId);
        return newTokenId;
    }
    // CREATE NFT ITEM: create an NFT item from ERC721 token and price (owner: , sold: false)
    function createNftItem(uint256 tokenId) private {
        _idToNftItem[tokenId] = NftItem(
            tokenId, 
            payable(msg.sender), 
            0,
            false
        );

        emit NftItemCreated(tokenId, msg.sender);
    }
    // LIST NFT ITEM: 
    function listNftItem(uint256 tokenId, uint256 price) public payable minValue(price){
        require(msg.value == listingFee, "Make sure submit value == listing price");
        NftItem storage nftItem = _idToNftItem[tokenId];

        require(nftItem.owner == msg.sender, "Only NFT item owner can call this func");
        nftItem.price = price;
        nftItem.isListed = true;
        payable(owner).transfer(msg.value); // payout listing fee for market owner
        _itemsListed.increment();

        emit NftItemListed(tokenId, msg.sender, price);
    }
    // UPDATE NFT ITEM PRICE
    function updateItemPrice(uint256 tokenId, uint256 price) public minValue(price) {
        NftItem storage nftItem = _idToNftItem[tokenId];
        require(nftItem.owner == msg.sender, "Only NFT item owner can call this func");
        nftItem.price = price;
    }
    // UNLIST NFT ITEM
    function unlistNftItem(uint256 tokenId) public {
        NftItem storage nftItem = _idToNftItem[tokenId];
        require(nftItem.owner == msg.sender, "Only NFT item owner can call this func");
        require(nftItem.isListed == true, "NFT Item is not listed");
        nftItem.isListed = false;
        _itemsListed.decrement();
    }
    // BUY NFT: make a NFT-Item purchase
    function buyNftItem(uint256 tokenId) public payable {
        NftItem storage nftItem = _idToNftItem[tokenId];
        require(msg.value == nftItem.price, "Make sure submit value == price");
        require(msg.sender != nftItem.owner, "Make sure buyer != owner");

        _transfer(nftItem.owner, msg.sender, tokenId);
        payable(nftItem.owner).transfer(msg.value); // payout NFT price for seller

        _itemsListed.decrement();
        nftItem.owner = payable(msg.sender);
        nftItem.isListed = false;
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
        uint256 currentIndex = 0;

        NftItem[] memory items = new NftItem[](_itemsListed.current());
        for (uint256 i = 1; i <= itemCount; i++) {
            if (_idToNftItem[i].isListed == true) {
                items[currentIndex] = _idToNftItem[i];
                currentIndex += 1;
            }
        }
        return items;
    }
    // GET_MY_NFT: get all NFT owned by msg.sender
    function getMyNFT() public view returns(NftItem[] memory) {
        uint256 totalCount = _tokenIds.current();
        uint256 totalUserItem = balanceOf(msg.sender);
        uint256 currentIndex = 0;

        NftItem[] memory items = new NftItem[](totalUserItem);
        for (uint256 i = 1; i <= totalCount; i++) {
            if(_idToNftItem[i].owner == msg.sender) {
                items[currentIndex] = _idToNftItem[i];
                currentIndex += 1;
            }
        }
        return items;
    }
}