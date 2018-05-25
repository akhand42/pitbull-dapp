pragma solidity ^0.4.18;

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
    function tokenOfOwnerByIndex(address _owner, uint256 _index) public view returns (uint256);
    // function tokenMetadata(uint256 _tokenId) public view returns (string infoUrl);

    // Required Events
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
}

contract ArtistToken is AccessControl, ERC721 {

  address owner;
  uint256 minTokenPrice;
  uint256 tokenCount;
  uint256 artistCount;
  struct ArtistToken {
    uint256 artistGene; // beyonce, pitbull, etc
    bytes32 name;
  }
  ArtistToken[] public artist;
  mapping (uint256 => address) public artistTokenIdToOwner;
  mapping (address => uint256[]) internal ownerToArtistTokens;

  // Constructor
  function ArtistToken(uint256 minTokenPrice) public {
    owner = msg.sender;
    minTokenPrice = minTokenPrice;
    tokenCount = 0;
  }

  // Artists call this function to create their own ICO.
  function registerArtist(bytes32 _name, uint256 count) public payable returns (uint256 artistGene){
    // TODO: Overflow fix!!!!
    require(msg.value >= count * minTokenPrice);
    uint artistGene = artistCount; // e.g. 1 for KanyeToken, 2 for DiddyToken
    artistCount += 1;
    for (uint i = 0; i < count; i++){
        uint tokenId = artist.push(ArtistToken(artistGene, _name));
        artistTokenIdToOwner[tokenId] = msg.sender;
        ownerToArtistTokens[msg.sender].push(tokenId);
    }
    tokenCount += count;
    return artistGene;
  }

  function implementsERC721() public pure returns (bool) {
    return true;
  }

  function totalSupply() public view returns (uint256) {
    return tokenCount;
  }

  function balanceOf(address _owner) public view returns (uint256 balance) {
    return ownerToArtistTokens[_owner].length;
  }

  function ownerOf(uint256 _tokenId) public view returns (address owner) {
    address owner = artistTokenIdToOwner[_tokenId];
    require(owner != address(0));
    return owner;
  }

  function transfer(address _to, uint256 _tokenId) public {
    require(_to != address(0));
    require(artistTokenIdToOwner[_tokenId] == msg.sender);
    artistTokenIdToOwner[_tokenId] = _to;
    uint256[] storage userTokens = ownerToArtistTokens[msg.sender];
    for (int i = 0; i < userTokens.length; i++){
      if (userTokens[i] == _tokenId){
        delete userTokens[i];
        ownerToArtistTokens[_to].push(_tokenId);
        break;
      }
    }
    Transfer(msg.sender, _to, _tokenId);
  }

  function approve(address _to, uint256 _tokenId) public {
    require(tulipToOwner[_tokenId] == msg.sender);
    tulipToApproved[_tokenId] = _to;

    Approval(msg.sender, _to, _tokenId);
  }

  function transferFrom(address _from, address _to, uint256 _tokenId) public {
    require(_to != address(0));
    require(tulipToApproved[_tokenId] == msg.sender);
    require(tulipToOwner[_tokenId] == _from);

    _transferTulip(_from, _to, _tokenId);
    Transfer(_from, _to, _tokenId);
  }

  function name() public pure returns (string) {
    return "Artist Token";
  }

  function symbol() public pure returns (string) {
    return "ARTE";
  }

}

contract TulipSales is TulipToken {
  event Purchase(address indexed owner, uint256 unitPrice, uint32 amount);

  uint128 public increasePeriod = 6000; // around 1 day
  uint128 public startBlock;
  uint256[] public genToStartPrice;
  uint256[23] internal exp15;

  function renameTulip(uint256 _id, bytes32 _name) public {
    require(tulipToOwner[_id] == msg.sender);

    tulips[_id].name = _name;
  }

  function withdrawBalance(uint256 _amount) external onlyAdmins {
    require(_amount <= this.balance);

    msg.sender.transfer(_amount);
  }
contract TulipCore is TulipSales {
  event ContractUpgrade(address newContract);
  event MaintenanceUpdate(bool maintenance);

  bool public underMaintenance = false;
  bool public deprecated = false;
  address public newContractAddress;

  function TulipCore() public {
    owner = msg.sender;
  }

  function getTulip(uint256 _id) public view returns (
    uint256 genes,
    uint256 createTime,
    string name
  ) {
    Tulip storage tulip = tulips[_id];
    genes = tulip.genes;
    createTime = tulip.createTime;

    bytes memory byteArray = new bytes(32);
    for (uint8 i = 0; i < 32; i++) {
      byteArray[i] = tulip.name[i];
    }
    name = string(byteArray);
  }

  function myTulips() public view returns (uint256[]) {
    uint256[] memory tulipsMemory = ownerToTulips[msg.sender];
    return tulipsMemory;
  }

  function myTulipsBatched(uint256 _startIndex, uint16 _maxAmount) public view returns (
    uint256[] tulipIds,
    uint256 amountRemaining
  ) {
    uint256[] storage tulipArr = ownerToTulips[msg.sender];
    int256 j = int256(tulipArr.length) - 1 - int256(_startIndex);
    uint256 amount = _maxAmount;

    if (j < 0) {
      return (
        new uint256[](0),
        0
      );
    } else if (j + 1 < _maxAmount) {
      amount = uint256(j + 1);
    }
    uint256[] memory resultIds = new uint256[](amount);

    for (uint16 i = 0; i < amount; i++) {
      resultIds[i] = tulipArr[uint256(j)];
      j--;
    }

    return (
      resultIds,
      uint256(j+1)
    );
  }

  function setMaintenance(bool _underMaintenance) public onlyAdmins {
    underMaintenance = _underMaintenance;
    MaintenanceUpdate(underMaintenance);
  }

  function upgradeContract(address _newContractAddress) public onlyAdmins {
    newContractAddress = _newContractAddress;
    deprecated = true;
    ContractUpgrade(_newContractAddress);
  }
}
