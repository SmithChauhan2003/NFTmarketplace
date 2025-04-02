// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

import "hardhat/console.sol";

contract NFTMarketplace is ERC721URIStorage, ReentrancyGuard {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;
    Counters.Counter private _itemsSold;
    Counters.Counter private _auctionIds;

    uint256 listingPrice = 0.000001 ether;
    address payable owner;

    mapping(uint256 => MarketItem) private idToMarketItem;
    mapping(uint256 => Auction) private idToAuction;
    mapping(uint256 => mapping(address => uint256)) private auctionBids;

    struct MarketItem {
        uint256 tokenId;
        address payable seller;
        address payable owner;
        uint256 price;
        bool sold;
    }

    struct Auction {
        uint256 auctionId;
        uint256 tokenId;
        address payable seller;
        uint256 startingPrice;
        uint256 highestBid;
        address payable highestBidder;
        uint256 endTime;
        bool ended;
    }

    event MarketItemCreated(
        uint256 indexed tokenId,
        address seller,
        address owner,
        uint256 price,
        bool sold
    );

    event AuctionCreated(
        uint256 indexed auctionId,
        uint256 indexed tokenId,
        address seller,
        uint256 startingPrice,
        uint256 endTime
    );

    event BidPlaced(
        uint256 indexed auctionId,
        uint256 indexed tokenId,
        address bidder,
        uint256 bidAmount
    );

    event AuctionEnded(
        uint256 indexed auctionId,
        uint256 indexed tokenId,
        address winner,
        uint256 winningBid
    );

    event AuctionCancelled(
        uint256 indexed auctionId,
        uint256 indexed tokenId
    );

    modifier onlyOwner() {
        require(
            msg.sender == owner,
            "only owner of the marketplace can change the listing price"
        );
        _;
    }

    constructor() ERC721("Metaverse Tokens", "METT") {
        owner = payable(msg.sender);
    }

    /* Updates the listing price of the contract */
    function updateListingPrice(uint256 _listingPrice)
        public
        payable
        onlyOwner
    {
        require(
            owner == msg.sender,
            "Only marketplace owner can update listing price."
        );
        listingPrice = _listingPrice;
    }

    /* Returns the listing price of the contract */
    function getListingPrice() public view returns (uint256) {
        return listingPrice;
    }

    /* Mints a token and lists it in the marketplace */
    function createToken(string memory tokenURI, uint256 price)
        public
        payable
        returns (uint256)
    {
        _tokenIds.increment();
        uint256 newTokenId = _tokenIds.current();

        _mint(msg.sender, newTokenId);
        _setTokenURI(newTokenId, tokenURI);
        createMarketItem(newTokenId, price);
        return newTokenId;
    }

    function createMarketItem(uint256 tokenId, uint256 price) private {
        require(price > 0, "Price must be at least 1 wei");
        require(
            msg.value == listingPrice,
            "Price must be equal to listing price"
        );

        idToMarketItem[tokenId] = MarketItem(
            tokenId,
            payable(msg.sender),
            payable(address(this)),
            price,
            false
        );

        _transfer(msg.sender, address(this), tokenId);
        emit MarketItemCreated(
            tokenId,
            msg.sender,
            address(this),
            price,
            false
        );
    }

    /* allows someone to resell a token they have purchased */
    function resellToken(uint256 tokenId, uint256 price) public payable {
        console.log(price);
        require(
            idToMarketItem[tokenId].owner == msg.sender,
            "Only item owner can perform this operation"
        );
        require(
            msg.value == listingPrice,
            "Price must be equal to listing price"
        );
        idToMarketItem[tokenId].sold = false;
        idToMarketItem[tokenId].price = price;
        idToMarketItem[tokenId].seller = payable(msg.sender);
        idToMarketItem[tokenId].owner = payable(address(this));
        _itemsSold.decrement();

        _transfer(msg.sender, address(this), tokenId);
    }

    /* Creates the sale of a marketplace item */
    /* Transfers ownership of the item, as well as funds between parties */
    function createMarketSale(uint256 tokenId) public payable {
        uint256 price = idToMarketItem[tokenId].price;
        require(
            msg.value == price,
            "Please submit the asking price in order to complete the purchase"
        );
        idToMarketItem[tokenId].owner = payable(msg.sender);
        idToMarketItem[tokenId].sold = true;
        _itemsSold.increment();
        _transfer(address(this), msg.sender, tokenId);
        payable(owner).transfer(listingPrice);
        payable(idToMarketItem[tokenId].seller).transfer(msg.value);
        idToMarketItem[tokenId].seller = payable(address(0));
    }

    /* Returns all unsold market items */
    function fetchMarketItems() public view returns (MarketItem[] memory) {
        uint256 itemCount = _tokenIds.current();
        uint256 unsoldItemCount = _tokenIds.current() - _itemsSold.current();
        uint256 currentIndex = 0;

        MarketItem[] memory items = new MarketItem[](unsoldItemCount);
        for (uint256 i = 0; i < itemCount; i++) {
            if (idToMarketItem[i + 1].owner == address(this)) {
                uint256 currentId = i + 1;
                MarketItem storage currentItem = idToMarketItem[currentId];
                items[currentIndex] = currentItem;
                currentIndex += 1;
            }
        }
        return items;
    }

    /* Returns only items that a user has purchased */
    function fetchMyNFTs() public view returns (MarketItem[] memory) {
        uint256 totalItemCount = _tokenIds.current();
        uint256 itemCount = 0;
        uint256 currentIndex = 0;

        for (uint256 i = 0; i < totalItemCount; i++) {
            if (idToMarketItem[i + 1].owner == msg.sender) {
                itemCount += 1;
            }
        }

        MarketItem[] memory items = new MarketItem[](itemCount);
        for (uint256 i = 0; i < totalItemCount; i++) {
            if (idToMarketItem[i + 1].owner == msg.sender) {
                uint256 currentId = i + 1;
                MarketItem storage currentItem = idToMarketItem[currentId];
                items[currentIndex] = currentItem;
                currentIndex += 1;
            }
        }
        return items;
    }

    /* Returns only items a user has listed */
    function fetchItemsListed() public view returns (MarketItem[] memory) {
        uint256 totalItemCount = _tokenIds.current();
        uint256 itemCount = 0;
        uint256 currentIndex = 0;

        for (uint256 i = 0; i < totalItemCount; i++) {
            if (idToMarketItem[i + 1].seller == msg.sender) {
                itemCount += 1;
            }
        }

        MarketItem[] memory items = new MarketItem[](itemCount);
        for (uint256 i = 0; i < totalItemCount; i++) {
            if (idToMarketItem[i + 1].seller == msg.sender) {
                uint256 currentId = i + 1;
                MarketItem storage currentItem = idToMarketItem[currentId];
                items[currentIndex] = currentItem;
                currentIndex += 1;
            }
        }
        return items;
    }

    // AUCTION FUNCTIONALITY

    /* Creates an auction for a token */
    function createAuction(
        uint256 tokenId,
        uint256 startingPrice,
        uint256 auctionDuration
    ) public payable nonReentrant {
        require(
            idToMarketItem[tokenId].owner == msg.sender,
            "Only item owner can start an auction"
        );
        require(
            msg.value == listingPrice,
            "Price must be equal to listing price"
        );
        require(startingPrice > 0, "Starting price must be greater than 0");
        require(auctionDuration > 0, "Auction duration must be greater than 0");

        _auctionIds.increment();
        uint256 auctionId = _auctionIds.current();
        
        // Transfer NFT to contract
        _transfer(msg.sender, address(this), tokenId);
        
        // Create auction
        idToAuction[auctionId] = Auction(
            auctionId,
            tokenId,
            payable(msg.sender),
            startingPrice,
            0,
            payable(address(0)),
            block.timestamp + auctionDuration,
            false
        );
        
        // Update market item
        idToMarketItem[tokenId].owner = payable(address(this));
        idToMarketItem[tokenId].seller = payable(msg.sender);
        
        emit AuctionCreated(
            auctionId,
            tokenId,
            msg.sender,
            startingPrice,
            block.timestamp + auctionDuration
        );
    }

    /* Place a bid on an auction */
    function placeBid(uint256 auctionId) public payable nonReentrant {
        Auction storage auction = idToAuction[auctionId];
        
        require(auction.auctionId == auctionId, "Auction does not exist");
        require(!auction.ended, "Auction already ended");
        require(block.timestamp < auction.endTime, "Auction already ended");
        require(auction.seller != msg.sender, "Seller cannot bid on their own auction");
        require(msg.value > auction.highestBid, "Bid must be higher than current highest bid");
        require(msg.value >= auction.startingPrice, "Bid must be at least the starting price");
        
        // Refund the previous highest bidder
        if (auction.highestBidder != address(0)) {
            payable(auction.highestBidder).transfer(auction.highestBid);
        }
        
        // Update auction with new highest bid
        auction.highestBid = msg.value;
        auction.highestBidder = payable(msg.sender);
        
        // Store individual bid for record keeping
        auctionBids[auctionId][msg.sender] = msg.value;
        
        emit BidPlaced(auctionId, auction.tokenId, msg.sender, msg.value);
    }

    /* End an auction and transfer NFT to winner */
    function endAuction(uint256 auctionId) public nonReentrant {
        Auction storage auction = idToAuction[auctionId];
        
        require(auction.auctionId == auctionId, "Auction does not exist");
        require(!auction.ended, "Auction already ended");
        require(
            msg.sender == auction.seller || block.timestamp >= auction.endTime,
            "Only seller can end auction before end time"
        );
        
        auction.ended = true;
        
        if (auction.highestBidder != address(0)) {
            // Transfer NFT to highest bidder
            _transfer(address(this), auction.highestBidder, auction.tokenId);
            
            // Transfer funds to seller
            payable(auction.seller).transfer(auction.highestBid);
            
            // Transfer listing fee to marketplace owner
            payable(owner).transfer(listingPrice);
            
            // Update market item
            idToMarketItem[auction.tokenId].owner = auction.highestBidder;
            idToMarketItem[auction.tokenId].sold = true;
            idToMarketItem[auction.tokenId].seller = payable(address(0));
            _itemsSold.increment();
            
            emit AuctionEnded(
                auctionId,
                auction.tokenId,
                auction.highestBidder,
                auction.highestBid
            );
        } else {
            // No bids were placed, return NFT to seller
            _transfer(address(this), auction.seller, auction.tokenId);
            
            // Update market item
            idToMarketItem[auction.tokenId].owner = auction.seller;
            idToMarketItem[auction.tokenId].seller = payable(address(0));
            
            emit AuctionCancelled(auctionId, auction.tokenId);
        }
    }

    /* Cancel auction if no bids have been placed */
    function cancelAuction(uint256 auctionId) public nonReentrant {
        Auction storage auction = idToAuction[auctionId];
        
        require(auction.auctionId == auctionId, "Auction does not exist");
        require(!auction.ended, "Auction already ended");
        require(auction.seller == msg.sender, "Only seller can cancel auction");
        require(auction.highestBidder == address(0), "Cannot cancel auction with bids");
        
        auction.ended = true;
        
        // Return NFT to seller
        _transfer(address(this), auction.seller, auction.tokenId);
        
        // Update market item
        idToMarketItem[auction.tokenId].owner = auction.seller;
        idToMarketItem[auction.tokenId].seller = payable(address(0));
        
        emit AuctionCancelled(auctionId, auction.tokenId);
    }

    /* Get auction by ID */
    function getAuction(uint256 auctionId) public view returns (
        uint256 tokenId,
        address seller,
        uint256 startingPrice,
        uint256 highestBid,
        address highestBidder,
        uint256 endTime,
        bool ended
    ) {
        Auction storage auction = idToAuction[auctionId];
        require(auction.auctionId == auctionId, "Auction does not exist");
        
        return (
            auction.tokenId,
            auction.seller,
            auction.startingPrice,
            auction.highestBid,
            auction.highestBidder,
            auction.endTime,
            auction.ended
        );
    }

    /* Get all active auctions */
    function fetchActiveAuctions() public view returns (Auction[] memory) {
        uint256 totalAuctionCount = _auctionIds.current();
        uint256 activeAuctionCount = 0;
        
        // Count active auctions
        for (uint256 i = 1; i <= totalAuctionCount; i++) {
            if (!idToAuction[i].ended && block.timestamp < idToAuction[i].endTime) {
                activeAuctionCount++;
            }
        }
        
        // Create array of active auctions
        Auction[] memory auctions = new Auction[](activeAuctionCount);
        uint256 currentIndex = 0;
        
        for (uint256 i = 1; i <= totalAuctionCount; i++) {
            if (!idToAuction[i].ended && block.timestamp < idToAuction[i].endTime) {
                Auction storage auction = idToAuction[i];
                auctions[currentIndex] = auction;
                currentIndex++;
            }
        }
        
        return auctions;
    }

    /* Get auctions created by the caller */
    function fetchMyAuctions() public view returns (Auction[] memory) {
        uint256 totalAuctionCount = _auctionIds.current();
        uint256 myAuctionCount = 0;
        
        // Count my auctions
        for (uint256 i = 1; i <= totalAuctionCount; i++) {
            if (idToAuction[i].seller == msg.sender) {
                myAuctionCount++;
            }
        }
        
        // Create array of my auctions
        Auction[] memory auctions = new Auction[](myAuctionCount);
        uint256 currentIndex = 0;
        
        for (uint256 i = 1; i <= totalAuctionCount; i++) {
            if (idToAuction[i].seller == msg.sender) {
                Auction storage auction = idToAuction[i];
                auctions[currentIndex] = auction;
                currentIndex++;
            }
        }
        
        return auctions;
    }

    /* Get auctions where the caller is the highest bidder */
    function fetchMyBids() public view returns (Auction[] memory) {
        uint256 totalAuctionCount = _auctionIds.current();
        uint256 myBidCount = 0;
        
        // Count auctions where I'm the highest bidder
        for (uint256 i = 1; i <= totalAuctionCount; i++) {
            if (idToAuction[i].highestBidder == msg.sender && !idToAuction[i].ended) {
                myBidCount++;
            }
        }
        
        // Create array of auctions where I'm the highest bidder
        Auction[] memory auctions = new Auction[](myBidCount);
        uint256 currentIndex = 0;
        
        for (uint256 i = 1; i <= totalAuctionCount; i++) {
            if (idToAuction[i].highestBidder == msg.sender && !idToAuction[i].ended) {
                Auction storage auction = idToAuction[i];
                auctions[currentIndex] = auction;
                currentIndex++;
            }
        }
        
        return auctions;
    }
    
    /* Get total number of auctions */
    function getAuctionCount() public view returns (uint256) {
        return _auctionIds.current();
    }
}