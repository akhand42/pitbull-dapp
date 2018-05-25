pragma solidity ^0.4.21;


/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
    if (a == 0) {
      return 0;
    }
    c = a * b;
    assert(c / a == b);
    return c;
  }

  /**
  * @dev Integer division of two numbers, truncating the quotient.
  */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    // uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold
    return a / b;
  }

  /**
  * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  /**
  * @dev Adds two numbers, throws on overflow.
  */
  function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
    c = a + b;
    assert(c >= a);
    return c;
  }
}


contract AccessControl {
  address public owner;
  address[] public admins;

  modifier onlyOwner {
    require(msg.sender == owner);
    _;
  }

  modifier onlyAdmins {
    bool found = false;

    for (uint i = 0; i < admins.length; i++) {
      if (admins[i] == msg.sender) {
        found = true;
        break;
      }
    }

    require(found);
    _;
  }

  function addAdmin(address _adminAddress) public onlyOwner {
    admins.push(_adminAddress);
  }
}

contract ERC721 {
    // Required Functions
    function implementsERC721() public pure returns (bool);
    function totalSupply() public view returns (uint256);
    function balanceOf(address _owner) public view returns (uint256);
    function ownerOf(uint256 _tokenId) public view returns (address);
    function transfer(address _to, uint _tokenId) public;
    function approve(address _to, uint256 _tokenId) public;
    function transferFrom(address _from, address _to, uint256 _tokenId) public;

    // Optional Functions
    function name() public pure returns (string);
    function symbol() public pure returns (string);

    // Required Events
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
}

contract ArtistTokenContract is AccessControl, ERC721 {
  using SafeMath for uint256;
  address owner;
  uint256 minTokenPrice;
  uint256 tokenCount;
  uint256 artistCount;
  struct ArtistToken {
    uint256 artistGene; // beyonce, pitbull, etc
    bytes32 name;
    bool forSale;
    uint256 price;
  }
  ArtistToken[] public artist;
  mapping (uint256 => address) public artistTokenIdToOwner;
  // map from owner -> (map of artistGene -> artistTokens[])
  mapping (address => mapping(uint256 => uint256[])) internal ownerToArtistGeneMap;
  mapping (uint256 => address) public artistTokenToApproved;
  mapping (address => uint256) public userTokenCount;
  mapping (uint256 => address[]) public artistGeneToAddresses;
  // Constructor
  constructor () public {
    owner = msg.sender;
    minTokenPrice = 20000000000000; // around 0.012 cents per token (price at $600 a ether)
    tokenCount = 0;
    artistCount = 0;
  }

  function myArtistTokens(uint256 artistGene) public view returns (uint256[]) {
    uint256[] memory artistTokens = ownerToArtistGeneMap[msg.sender][artistGene];
    return artistTokens;
  }

  function whoseArtistTokens(uint256 artistGene, address tokenOwner) public view returns (uint256[]) {
    uint256[] memory artistTokens = ownerToArtistGeneMap[tokenOwner][artistGene];
    return artistTokens;
  }

  function artistToAddresses(uint256 artistGene) public view returns (address[]) {
    address[] memory addresses = artistGeneToAddresses[artistGene];
    return addresses;
  }


  // Artists call this function to create their own ICO.
  function registerArtist(bytes32 _name, uint256 count, uint256 minPrice) public payable returns
   (uint256 artistGene){
    require(msg.value >= SafeMath.mul(count, minTokenPrice));
    artistGene = artistCount; // e.g. 1 for KanyeToken, 2 for DiddyToken
    artistCount += 1;
    for (uint i = 0; i < count; i++){
        uint tokenId = artist.push(ArtistToken(artistGene, _name, true, minPrice));
        artistTokenIdToOwner[tokenId] = msg.sender;
        ownerToArtistGeneMap[msg.sender][artistGene].push(tokenId);
    }
    tokenCount += count;
    userTokenCount[msg.sender] += count;
    artistGeneToAddresses[artistGene].push(msg.sender);
    return artistGene;
  }

  function implementsERC721() public pure returns (bool) {
    return true;
  }

  function totalSupply() public view returns (uint256) {
    return tokenCount;
  }

  function balanceOf(address _owner) public view returns (uint256 balance) {
    return userTokenCount[_owner];
  }

  function ownerOf(uint256 _tokenId) public view returns (address artistOwner) {
    artistOwner = artistTokenIdToOwner[_tokenId];
    require(artistOwner != address(0));
    return artistOwner;
  }

  function transfer(address _to, uint256 _tokenId) public {
    _transferToken(msg.sender, _to, _tokenId);
  }

  function _transferToken(address _from, address _to, uint256 _tokenId) internal returns (bool success){
    require(_to != address(0));
    require(artistTokenIdToOwner[_tokenId] == _from);
    artistTokenIdToOwner[_tokenId] = _to;
    uint256 artistGene = artist[_tokenId].artistGene;
    uint256[] storage singleUserArtistTokens = ownerToArtistGeneMap[_from][artistGene];
    if (singleUserArtistTokens.length > 0){ // TODO: verify if this a valid way to check existence
      require(singleUserArtistTokens.length > 0);
      for (uint256 i = 0; i < singleUserArtistTokens.length; i++){
        uint256 artistTokenId = singleUserArtistTokens[i];
        if (artistTokenId == _tokenId){
          delete ownerToArtistGeneMap[_from][artistGene][i];
          if (ownerToArtistGeneMap[_from][artistGene].length == 0){
            // update artistGeneToAddresses to get rid of _from
            address[] storage addresses = artistGeneToAddresses[artistGene];
            for (uint256 artistIndex = 0; artistIndex < addresses.length; artistIndex++){
              if (addresses[artistIndex] == _from){
                delete artistGeneToAddresses[artistGene][artistIndex];
              }
            }
          }
          ownerToArtistGeneMap[_to][artistGene].push(_tokenId);
          artist[_tokenId].forSale = true;
          artistTokenToApproved[_tokenId] = 0x0;
          // update artistGeneToAddresses to keep track of who the artist tokens are owned by
          if (ownerToArtistGeneMap[_to][artistGene].length == 1){
            // new user
            artistGeneToAddresses[artistGene].push(_to);
          }
          emit Transfer(msg.sender, _to, _tokenId);
          return true;
        }
      }
    }
    return false;
  }

  function changePrice(uint256 artistGene, uint256 quantity, uint256 price) public {
    uint256[] storage singleUserArtistTokens = ownerToArtistGeneMap[msg.sender][artistGene];
    require(singleUserArtistTokens.length >= quantity && quantity >= 0);
    for (uint256 i = 0; i < singleUserArtistTokens.length; i++){
      ArtistToken storage token = artist[singleUserArtistTokens[i]];
      if (token.forSale == true){
        token.price = price;
      }
    }
  }

  function markNotForSale(uint256 artistGene, uint256 quantity) public {
    uint256[] storage singleUserArtistTokens = ownerToArtistGeneMap[msg.sender][artistGene];
    require(singleUserArtistTokens.length >= quantity && quantity >= 0);
    uint256 count = 0;
    for (uint256 i = 0; i < singleUserArtistTokens.length; i++){
      ArtistToken storage token = artist[singleUserArtistTokens[i]];
      if (token.forSale == true){
        token.forSale = false;
        count += 1;
        if (count == quantity){
          break;
        }
      }
    }
  }

  function markForSale(uint256 artistGene, uint256 quantity, uint256 price) public {
    uint256[] storage singleUserArtistTokens = ownerToArtistGeneMap[msg.sender][artistGene];
    require(singleUserArtistTokens.length >= quantity && quantity >= 0);
    changePrice(artistGene, quantity, price);
    uint256 count = 0;
    for (uint256 i = 0; i < singleUserArtistTokens.length; i++){
      ArtistToken storage token = artist[singleUserArtistTokens[i]];
      if (token.forSale == false){
        token.forSale = true;
        count += 1;
        token.price = price;
        if (count == quantity){
          break;
        }
      }
    }
  }

  function buyArtistTokensFromUser(uint256 artistGene, uint256 quantity, uint256 buyPrice, address seller, uint256 sellPrice) public payable returns (bool success){
    uint256[] storage singleUserArtistTokens = ownerToArtistGeneMap[seller][artistGene];
    require(singleUserArtistTokens.length >= quantity);
    uint256 totalEth = SafeMath.mul(quantity,buyPrice);
    uint256 forSaleCount = 0;
    for (uint256 i = 0; i < singleUserArtistTokens.length; i++){
      if (artist[singleUserArtistTokens[j]].forSale == true){
        forSaleCount += 1;
        if (msg.value < totalEth){
          // not enough money sent
          require(false);
        }
      }
    }
    require(forSaleCount >= quantity);
    uint256 sold = 0;
    for (uint256 j = 0; j < singleUserArtistTokens.length; j++){
      if (artist[singleUserArtistTokens[j]].forSale == true){
        require(_transferToken(seller, msg.sender, singleUserArtistTokens[j]));
        sold += 1;
        if (sold == quantity){
          changePrice(artistGene, quantity, sellPrice);
          return true;
        }
      }
    }
    return false;
  }

  function transferSameTokens(address _to, uint256 _artistId, uint256 number) public returns (bool success) {
    require(_to != address(0));
    require(ownerToArtistGeneMap[msg.sender][_artistId].length >= number);
    uint256[] storage userTokens = ownerToArtistGeneMap[msg.sender][_artistId];
    for (uint256 i = 0; i < userTokens.length; i++){
      require(_transferToken(msg.sender, _to, userTokens[i]));
    }
    return true;
  }

  function approve(address _to, uint256 _tokenId) public {
    require(artistTokenIdToOwner[_tokenId] == msg.sender);
    artistTokenToApproved[_tokenId] = _to;
    emit Approval(msg.sender, _to, _tokenId);
  }

  function transferFrom(address _from, address _to, uint256 _tokenId) public {
    require(_to != address(0));
    require(artistTokenToApproved[_tokenId] == msg.sender);
    require(artistTokenIdToOwner[_tokenId] == _from);
    _transferToken(_from, _to, _tokenId);
    emit Transfer(_from, _to, _tokenId);
  }

  function name() public pure returns (string) {
    return "Artist Token";
  }

  function symbol() public pure returns (string) {
    return "ARTE";
  }
}
