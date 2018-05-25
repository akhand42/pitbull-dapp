pragma solidity ^0.4.21;

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
  mapping (uint256 => address) public artistTokenToApproved;
  // Constructor
  constructor (uint256 minPrice) public {
    owner = msg.sender;
    minTokenPrice = minPrice;
    tokenCount = 0;
  }

  // Artists call this function to create their own ICO.
  function registerArtist(bytes32 _name, uint256 count) public payable returns (uint256 artistGene){
    // TODO: Overflow fix!!!!
    require(msg.value >= count * minTokenPrice);
    artistGene = artistCount; // e.g. 1 for KanyeToken, 2 for DiddyToken
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

  function ownerOf(uint256 _tokenId) public view returns (address artistOwner) {
    artistOwner = artistTokenIdToOwner[_tokenId];
    require(artistOwner != address(0));
    return artistOwner;
  }

  function transfer(address _to, uint256 _tokenId) public {
    _transferToken(msg.sender, _to, _tokenId);
  }

  function _transferToken(address _from, address _to, uint256 _tokenId) internal{
    require(_to != address(0));
    require(artistTokenIdToOwner[_tokenId] == _from);
    artistTokenIdToOwner[_tokenId] = _to;
    uint256[] storage userTokens = ownerToArtistTokens[_from];
    for (uint256 i = 0; i < userTokens.length; i++){
      if (userTokens[i] == _tokenId){
        delete userTokens[i];
        ownerToArtistTokens[_to].push(_tokenId);
        break;
      }
    }
    artistTokenToApproved[_tokenId] = 0x0;
    emit Transfer(msg.sender, _to, _tokenId);
  }

  function _transferSameTokens(address _to, uint256 _artistId, uint256 number) public returns (bool success) {
    require(_to != address(0));
    require(ownerToArtistTokens[msg.sender].length >= number); // sanity check but doesnt guarantee
    uint256[] storage userTokens = ownerToArtistTokens[msg.sender];
    uint256[] memory indices = new uint256[](number); // 453, 24, 2, 222
    uint256 count = 0;
    for (uint256 i = 0; i < userTokens.length; i++){
      if (artist[userTokens[i]].artistGene == _artistId){
        indices[count] = userTokens[i];
        count += 1;
      }
    }
    if (indices.length >= number){
      for (uint256 j = 0; j < number; j++){
        _transferToken(msg.sender, _to, indices[j]);
      }
      return true;
    }
    return false;
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
