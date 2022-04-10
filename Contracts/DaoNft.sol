// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract MyToken is ERC721, Ownable {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIdCounter;

    uint public TotalMintedNfts ;
    mapping(address => bool) public haveNft;
    mapping(address => uint) public whichTokenIdAddrHave; 
    mapping(uint => uint) public sellingPriceOfToken;

    address CollectionnOwner;

    constructor() ERC721("daoNft", "DNft") {
        TotalMintedNfts = 0;
        _tokenIdCounter.increment();//start the tokenIds from 1
        CollectionnOwner = msg.sender;
    }

    //onlyOwner modifer hai
    // collection owner ==>set Dao.sol
    // make dao.sol as owner sahi rahege
    // ADD to address coz to set a stream it would be called from dao contract
    function MintANft() public {
        require(!haveNft[msg.sender], 'You already own a nft');
        address to = msg.sender;
        uint256 tokenId = _tokenIdCounter.current();
        TotalMintedNfts += 1;
        whichTokenIdAddrHave[to] = _tokenIdCounter.current();
        haveNft[to] = true; //
        _tokenIdCounter.increment();
        _safeMint(to, tokenId);
        approve(CollectionnOwner, tokenId); //allow collection owner to do transfers
    }

    //may require modification need to send address msg.sender
    function setSellingPrice(uint _price) public{
        require(haveNft[msg.sender], 'You dont have a nft');
        uint tokenHolding = whichTokenIdAddrHave[msg.sender];
        sellingPriceOfToken[tokenHolding] = _price;
    }

    function BuyNft(address seller, address buyer) public{
        // buy nft from addres coz 1addres anyways has only 1 nft
        //require a certain payment or will handle in Dao
        //update states
        require(msg.sender == CollectionnOwner, 'You cant directly buy');
        haveNft[seller] = false;
        haveNft[buyer] = true;
        whichTokenIdAddrHave[buyer] = whichTokenIdAddrHave[seller];
        safeTransferFrom(seller, buyer, whichTokenIdAddrHave[seller]);
        whichTokenIdAddrHave[seller] = 0;
    }
}