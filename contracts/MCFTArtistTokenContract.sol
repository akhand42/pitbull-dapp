pragma experimental ABIEncoderV2;

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
    function individualSupply(uint256 classId) public view returns (uint256);
    function balanceOf(address owner, uint256 classId) public view returns (uint256);
    function classesOwned(address owner) public view returns (uint256[]);
    function transfer(address to, uint256 classId, uint256 quantity) public;
    function approve(address to, uint256 classId, uint256 quantity) public;
    function transferFrom(address from, address to, uint256 classId) public;

    // Optional Functions
    function name() public pure returns (string);
    function className(uint256 classId) public view returns (bytes32);
    function symbol() public pure returns (string);

    // Required Events
    event Transfer(address indexed from, address indexed to, uint256 indexed classId, uint256 quantity);
    event Approval(address indexed owner, address indexed approved, uint256 indexed classId, uint256 quantity);
}

contract MCFTArtistTokenContract is AccessControl, ERC1178 {
  using SafeMath for uint256;
  address public Owner;
  uint256 public tokenCount;
  uint256 currentClass;
  uint256 minTokenPrice;
  uint256 minCount;
  struct Transactor {
    address actor;
    uint256 amount;
  }
  mapping(uint256 => uint256) public classIdToSupply;
  mapping(address => mapping(uint256 => uint256)) ownerToClassToBalance;
  mapping(address => mapping(uint256 => Transactor)) approvals;
  mapping(uint256 => bytes32) public classNames;

  // Constructor
  constructor () public {
    Owner = msg.sender;
    currentClass = 1;
    tokenCount = 0;
    minCount = 10000; // min of 10000 tokens
    minTokenPrice = 20000000000000; // around 0.012 cents per token (price at $600 a ether)
  }

  function implementsERC1178() public pure returns (bool) {
    return true;
  }

  function totalSupply() public view returns (uint256) {
    return tokenCount;
  }

  function individualSupply(uint256 classId) public view returns (uint256) {
    return classIdToSupply[classId];
  }

  function balanceOf(address owner, uint256 classId) public view returns (uint256) {
    /* if (ownerToClassToBalance[owner] == 0) return 0; */
    // TODO: make checks to see if ownerToClassToBalance[owner] and return 0 if u get the empty mapping
    return ownerToClassToBalance[owner][classId];
  }

  // class of 0 is meaningless and should be ignored.
  function classesOwned(address owner) public view returns (uint256[]){
    uint256[] memory tempClasses = new uint256[](tokenCount);
    uint256 count = 0;
    for (uint256 i = 1; i < currentClass; i++){
      if (ownerToClassToBalance[owner][i] != 0){
        tempClasses[count] = ownerToClassToBalance[owner][i];
        count += 1;
      }
    }
    uint256[] memory classes = new uint256[](count);
    for (i = 0; i < count; i++){
      classes[i] = tempClasses[i];
    }
    return classes;
  }

  function transfer(address to, uint256 classId, uint256 quantity) public {
    require(ownerToClassToBalance[msg.sender][classId] >= quantity);
    ownerToClassToBalance[msg.sender][classId] -= quantity;
    ownerToClassToBalance[to][classId] += quantity;
    Transactor memory zeroApproval;
    zeroApproval = Transactor(0x0, 0);
    approvals[msg.sender][classId] = zeroApproval;
  }

  function approve(address to, uint256 classId, uint256 quantity) public {
    require(ownerToClassToBalance[msg.sender][classId] >= quantity);
    Transactor memory takerApproval;
    takerApproval = Transactor(to, quantity);
    approvals[msg.sender][classId] = takerApproval;
    emit Approval(msg.sender, to, classId, quantity);
  }

  function transferFrom(address from, address to, uint256 classId) public {
    Transactor storage takerApproval = approvals[from][classId];
    uint256 quantity = takerApproval.amount;
    require(takerApproval.actor == to && quantity >= ownerToClassToBalance[from][classId]);
    ownerToClassToBalance[from][classId] -= quantity;
    ownerToClassToBalance[to][classId] += quantity;
    Transactor memory zeroApproval;
    zeroApproval = Transactor(0x0, 0);
    approvals[from][classId] = zeroApproval;
  }

  function name() public pure returns (string) {
    return "Multi-Class Artist Token";
  }

  function className(uint256 classId) public view returns (bytes32){
    return classNames[classId];
  }

  function symbol() public pure returns (string) {
    return "ARTE";
  }

  // Artists call this function to create their own token offering
  function registerArtist(bytes32 artistName, uint256 count) public payable{
    require(msg.value >= count * minTokenPrice && count >= minCount);
    ownerToClassToBalance[msg.sender][currentClass] = count;
    classNames[count] = artistName;
    currentClass += 1;
  }

}
