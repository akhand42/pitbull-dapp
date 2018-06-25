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

contract ERC1178 {
    // Required Functions
    function implementsERC1178() public pure returns (bool);
    function totalSupply() public view returns (uint256);
    function individualSupply(uint256 _classId) public view returns (uint256);
    function balanceOf(address owner, uint256 classId) public view returns (uint256);
    function classesOwned(address owner) public view returns (uint256[]);
    function transfer(address to, uint256 classId, uint256 quantity) public;
    function approve(address to, uint256 classId, uint256 quantity) public;
    function transferFrom(address from, address to, uint256 tokenId) public;

    // Optional Functions
    function name() public pure returns (string);
    function className(uint256 classId) public pure returns (string);
    function symbol() public pure returns (string);

    // Required Events
    event Transfer(address indexed from, address indexed to, uint256 indexed classId, uint256 indexed quantity);
    event Approval(address indexed owner, address indexed approved, uint256 indexed classId, uint256 indexed quantity);
}

contract ArtistTokenContract is AccessControl, ERC1178 {
  using SafeMath for uint256;
  address public owner;
  uint256 public tokenCount;
  uint256 currentClass;
  struct Transactor {
    address actor;
    uint256 amount;
  }
  mapping(uint256 => uint256) public classIdToSupply;
  mapping(address => mapping(uint256 => uint256)) ownerToClassToBalance;
  mapping(Transactor => Transactor) approvals;


  // Constructor
  constructor () public {
    owner = msg.sender;
    tokenCount = 0;
    currentClass = 1;
  }

  function implementsERC1178() public pure returns (bool) {
    return true;
  }

  function totalSupply() public view returns (uint256) {
    return tokenCount;
  }

  function individualSupply(uint256 classId) public view returns (uint256) {
    return classIdToSupply[_classId];
  }

  function balanceOf(address owner, uint256 classId) public view returns (uint256) {
    /* if (addressToClassToBalance[_owner] == 0) return 0; */
    // TODO: make checks to see if addressToClassToBalance[_owner] and return 0 if u get the empty mapping
    return ownerToClassToBalance[owner][classId];
  }

  // class of 0 is meaningless and should be ignored.
  function classesOwned(address owner) public view returns (uint256[]){
    uint256[] memory tempClasses = new uint256[](tokenCount);
    uint256 count = 0;
    for (uint256 i = 1; i < currentClass; i++){
      if (addressToClassToBalance[_owner][i] != 0){
        tempClasses[count] = addressToClassToBalance[_owner][i];
        count += 1;
      }
    }
    uint256[] memory classes = new uint256[](count);
    for (i = 0; i < count; i++){
      classes[i] = tempClasses[i]
    }
    return classes;
  }

  function transfer(address to, uint256 classId, uint256 quantity) public {
    require(addressToClassToBalance[msg.sender][classId] >= quantity);
    addressToClassToBalance[msg.sender][classId] -= quantity;
    addressToClassToBalance[to][classId] += quantity;
  }

  function approve(address to, uint256 classId, uint256 quantity) public {
    require(ownerToClassToBalance[msg.sender][classId] >= quantity);
    struct Transactor ownerApproval = Transactor(msg.sender, classId);
    struct Transactor takerApproval = Transactor(to, quantity);
    approvals[ownerApproval] = takerApproval;
    emit Approval(msg.sender, to, classId, quantity);
  }

  function transferFrom(address _from, address _to, uint256 _tokenId) public {

    emit Transfer(_from, _to, _tokenId);
  }

  function name() public pure returns (string) {
    return "Artist Token";
  }

  function className(uint256 classId) public pure returns (string){

  }

  function symbol() public pure returns (string) {
    return "ARTE";
  }

  // non-ERC721 functions

  function myArtistTokens(uint256 artistGene) public view returns (uint256[]) {
    return artistTokens;
  }

  function numArtists() public view returns (uint256) {
    return artistCount;
  }

  function artistToAddresses(uint256 artistGene) public view returns (address[]) {
    return addresses;
  }

  // Artists call this function to create their own ICO.
  function registerArtist(bytes32 _name, uint256 count, uint256 minPrice) public payable{
    require(msg.value >= count * minTokenPrice);
    uint256 artistGene = artistCount; // e.g. 1 for KanyeToken, 2 for DiddyToken
    artistCount += 1;
    for (uint256 i = 0; i < count; i++){
        uint256 tokenId = artist.push(ArtistToken(artistGene, _name, true, minPrice));
        artistTokenIdToOwner[tokenId] = msg.sender;
        ownerToArtistGeneMap[msg.sender][artistGene].push(tokenId);
    }
    tokenCount += count;
    userTokenCount[msg.sender] += count;
    artistGeneToAddresses[artistGene].push(msg.sender);
  }

}
