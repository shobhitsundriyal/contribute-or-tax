// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract DaoNft is ERC721, Ownable {
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
    function MintANft(address _to) external {
        require(!haveNft[_to], 'You already own a nft');
        // address to = msg.sender;
        uint256 tokenId = _tokenIdCounter.current();
        TotalMintedNfts += 1;
        whichTokenIdAddrHave[_to] = _tokenIdCounter.current();
        haveNft[_to] = true; //
        _tokenIdCounter.increment();
        _safeMint(_to, tokenId);
        setApprovalForAll(CollectionnOwner, true); //allow collection owner to do transfers
    }

    //may require modification need to send address msg.sender
    function setSellingPrice(uint _price, address _of) external{
        require(haveNft[_of], 'You dont have a nft');
        uint tokenHolding = whichTokenIdAddrHave[_of];
        sellingPriceOfToken[tokenHolding] = _price;
    }

    function BuyNft(address seller, address buyer) external{
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

    function yo() external view onlyOwner returns(bool){
        return true;
    }
}

interface IERC20 {
    function transfer(address _to, uint256 _value) external returns (bool);
    
    // don't need to define other functions, only using `transfer()` in this case
}

//Before any mint transfer DaoNft ownership to 
contract DaoLogic{

    address DaoOwner;
    bool isMintingOn;

    DaoNft nftContract;
    address public nftContractAddress;
    constructor(address _collectionAddr){
        nftContract = DaoNft(_collectionAddr);
        nftContractAddress = _collectionAddr;
        DaoOwner = msg.sender; //normally this should be multi sig of many dao members but for now its fine.
        IERC20 fTUSDx = IERC20(address(0xB20200908d60f1d7bc68594f677bC15070a87504));
    }

    modifier isDaoOwner(){
        require(DaoOwner == msg.sender, 'This action is reserved for Dao Owner');
        _;
    }

    function setIsMintingOn(bool _val) public isDaoOwner{
        isMintingOn = _val;
    }

    function getMeNft(uint _sellingPrice) public {
        require(isMintingOn, 'The minting is temopralily paused');
        nftContract.MintANft(msg.sender);
        nftContract.setSellingPrice(_sellingPrice, msg.sender);
        //start a stream from msg.sender to this
    }

    function isTaxDefaulter (address _checkAddr) internal returns (bool){
        return false;
    }

    function updateSellingPrice(uint _sellingPrice) public {
        require(!isTaxDefaulter(msg.sender), 'First clear off the taxes');
        nftContract.setSellingPrice(_sellingPrice, msg.sender);
        //update the stream from msg.sender to this
    }
    
    function updateTaxSlab(address _of) public {
        //update the stream accordin to tax slab
    }

    function buyANft(address _from) public {
        require(!isTaxDefaulter(_from), 'Seller needs to clear of the taxes');
        nftContract.BuyNft(_from, msg.sender);
        //close seller stream and start buyer's stream
    }
}