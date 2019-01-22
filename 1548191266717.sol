pragma solidity ^0.4.25;

//*******************************************************************//
//------------------------ SafeMath Library -------------------------//
//*******************************************************************//
/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold
    return c;
  }

  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}


//*******************************************************************//
//------------------ Main TR20 Structure -------------------//
//*******************************************************************//

contract TR20 {
    using SafeMath for uint256;
    string public name;
    string public symbol;
    uint256 public totalSupply;
    uint256 public decimals = 8;
    bool public safegaurd = false;
    //address private mainContractAddress = address(this);
    
    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;
    
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Burn(address indexed from, uint256 value);
    
    constructor (string memory tokenName, string memory tokenSymbol, uint256 initialSupply) public{
        name = tokenName;
        symbol = tokenSymbol;
        totalSupply = initialSupply.mul(10**decimals);
        balanceOf[msg.sender] = totalSupply;
    }
    
    function () payable external {}
    
    function _transfer(address _from, address _to, uint256 _value) internal {
        require(!safegaurd);
        require(balanceOf[_from] >= _value);
        require(balanceOf[_to].add(_value) > balanceOf[_to]);
        uint256 previousBalances = balanceOf[_from].add(balanceOf[_to]);
        
        balanceOf[_from] = balanceOf[_from].sub(_value);
        balanceOf[_to] = balanceOf[_to].add(_value);
        
        emit Transfer(_from, _to, _value);
        
        assert(balanceOf[_from].add(balanceOf[_to]) == previousBalances);
        
    }
    
    function transfer(address _to, uint256 _value) public returns (bool success){
        _transfer(msg.sender, _to, _value);
        return true;
    }
    
    function approve(address _spender, uint256 _value) public returns(bool success){
        require(!safegaurd);
        allowance[msg.sender][_spender] = _value;
        return true;
    }
    
    function transferFrom(address _from, address _to, uint256 _value) public returns(bool success){
        require(!safegaurd);
        require(_value <= allowance[_from][msg.sender]);
        allowance[_from][msg.sender] = allowance[_from][msg.sender].sub(_value);
        _transfer(_from, _to, _value);
        return true;
    }
    
    function burn(uint256 _value) public returns(bool success){
        require(!safegaurd);
        require(balanceOf[msg.sender] >= _value);
        
        balanceOf[msg.sender] = balanceOf[msg.sender].sub(_value);
        totalSupply = totalSupply.sub(_value);
        emit Burn(msg.sender, _value);
        return true;
    }
    
    function burnfrom(address _from, uint256 _value) public returns(bool success){
        require(!safegaurd);
        require(allowance[_from][msg.sender] > _value);
        require(_value <= allowance[_from][msg.sender]);
        
        allowance[_from][msg.sender] = allowance[_from][msg.sender].sub(_value);
        totalSupply = totalSupply.sub(_value);
        
        return true;
    }
}

contract hassantoken is TR20{
    string private tokenName = "HassanToken";
    string private tokenSymbol = "HST";
    uint256 private initialSupply = 10000000;
    uint256 public buyPrice = 10;
    
    constructor () TR20(tokenName, tokenSymbol, initialSupply) public {}
    
    function _transfer(address _from, address _to, uint256 _value) internal {
        require(!safegaurd);
        require(_to != address(0x0));
        require(balanceOf[_from] >= _value);
        require(balanceOf[_to].add(_value) >= balanceOf[_to]);
        
        //uint previousBalances = balanceOf[_from].add(balanceOf[_to]);
        balanceOf[_from] = balanceOf[_from].sub(_value);
        balanceOf[_to] = balanceOf[_to].add(_value);
        //assert(balanceOf[_from].add(balanceOf[_to] == previousBalances);
        emit Transfer(_from, _to, _value);
   
    }
    
    function buyTokens() payable public {
        require(!safegaurd);
        uint amount = msg.value.mul(1e8).mul(buyPrice);
        _transfer(this, msg.sender, amount);
    }
}