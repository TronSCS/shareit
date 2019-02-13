pragma solidity ^0.4.25; /*

*/ 

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
//------------------ Contract to Manage Ownership -------------------//
//*******************************************************************//
    
contract owned {
    address public owner;
    
     constructor () public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address newOwner) onlyOwner public {
        owner = newOwner;
    }
}
    
    

//*************************************************************//
//------------------ TR20 Standard Template -------------------//
//*************************************************************//
    
contract TokenTR20 {
    // Public variables of the token
    using SafeMath for uint256;
    string public name;
    string public symbol;
    uint256 public decimals = 8; 
    uint256 public totalSupply;
    bool public safeguard = false;  //putting safeguard on will halt all non-owner functions
    address private mainContractAddress = address(this);
    uint unfreezeLimitTime;  //Unfreeze Time Limit

    // This creates an array with all balances
    mapping (address => uint256) public balanceOf;
    mapping (address => uint256) public freezeOf;
    mapping (address => uint256) public freezeTime;
    mapping (address => mapping (address => uint256)) public allowance;
    

    // This generates a public event on the blockchain that will notify clients
    event Transfer(address indexed from, address indexed to, uint256 value);

    // This notifies clients about the amount burnt
    event Burn(address indexed from, uint256 value);
    /* This notifies clients about the amount frozen */
    event Freeze(address indexed from, uint256 value);
	
	/* This notifies clients about the amount unfrozen */
    event Unfreeze(address indexed from, uint256 value);

    /**
     * Constrctor function
     *
     * Initializes contract with initial supply tokens to the creator of the contract
     */
    constructor (
        uint256 initialSupply,
        string memory tokenName,
        string memory tokenSymbol
    ) public {
        totalSupply = initialSupply.mul(10**decimals);          // Update total supply with the decimal amount
        balanceOf[mainContractAddress] = totalSupply;// 100% will remain in contract
        name = tokenName;                                       // Set the name for display purposes
        symbol = tokenSymbol;                                   // Set the symbol for display purposes
        unfreezeLimitTime = 3600;                               // unfreese Time Limit 
        emit Transfer(address(0), mainContractAddress, totalSupply);
    }
    
    /**
     * fallback function. It just accepts any incoming fund into smart contract
     */
    function () payable external { }


    /**
     * Internal transfer, only can be called by this contract
     */
    function _transfer(address _from, address _to, uint _value) internal {
        require(!safeguard);
        // Prevent transfer to 0x0 address. Use burn() instead
        require(_to != address(0x0));
        // Check if the sender has enough
        require(balanceOf[_from] >= _value);
        // Check for overflows
        require(balanceOf[_to].add(_value) > balanceOf[_to]);
        // Save this for an assertion in the future
        uint previousBalances = balanceOf[_from].add(balanceOf[_to]);
        // Subtract from the sender
        balanceOf[_from] = balanceOf[_from].sub(_value);
        // Add the same to the recipient
        balanceOf[_to] = balanceOf[_to].add(_value);
        emit Transfer(_from, _to, _value);
        // Asserts are used to use static analysis to find bugs in your code. They should never fail
        assert(balanceOf[_from].add(balanceOf[_to]) == previousBalances);
    }

    /**
     * Transfer tokens
     *
     * Send `_value` tokens to `_to` from your account
     *
     * @param _to The address of the recipient
     * @param _value the amount to send
     */
    function transfer(address _to, uint256 _value) public returns (bool success) {
        _transfer(msg.sender, _to, _value);
        return true;
    }

    /**
     * Transfer tokens from other address
     *
     * Send `_value` tokens to `_to` in behalf of `_from`
     *
     * @param _from The address of the sender
     * @param _to The address of the recipient
     * @param _value the amount to send
     */
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(!safeguard);
        require(_value <= allowance[_from][msg.sender]);     // Check allowance
        allowance[_from][msg.sender] = allowance[_from][msg.sender].sub(_value);
        _transfer(_from, _to, _value);
        return true;
    }

    /**
     * Set allowance for other address
     *
     * Allows `_spender` to spend no more than `_value` tokens in your behalf
     *
     * @param _spender The address authorized to spend
     * @param _value the max amount they can spend
     */
    function approve(address _spender, uint256 _value) public
        returns (bool success) {
        require(!safeguard);
        allowance[msg.sender][_spender] = _value;
        return true;
    }

    /**
     * Destroy tokens
     *
     * Remove `_value` tokens from the system irreversibly
     *
     * @param _value the amount of money to burn
     */
    function burn(uint256 _value) public returns (bool success) {
        require(!safeguard);
        require(balanceOf[msg.sender] >= _value);   // Check if the sender has enough
        balanceOf[msg.sender] = balanceOf[msg.sender].sub(_value);            // Subtract from the sender
        totalSupply = totalSupply.sub(_value);                      // Updates totalSupply
        emit Burn(msg.sender, _value);
        return true;
    }

    /**
     * Destroy tokens from other account
     *
     * Remove `_value` tokens from the system irreversibly on behalf of `_from`.
     *
     * @param _from the address of the sender
     * @param _value the amount of money to burn
     */
    function burnFrom(address _from, uint256 _value) public returns (bool success) {
        require(!safeguard);
        require(balanceOf[_from] >= _value);                // Check if the targeted balance is enough
        require(_value <= allowance[_from][msg.sender]);    // Check allowance
        balanceOf[_from] = balanceOf[_from].sub(_value);                         // Subtract from the targeted balance
        allowance[_from][msg.sender] = allowance[_from][msg.sender].sub(_value);             // Subtract from the sender's allowance
        totalSupply = totalSupply.sub(_value);                              // Update totalSupply
        emit  Burn(_from, _value);
        return true;
    }
    
}

//**************************************************************************//
//---------------------  TOKEN MAIN CODE STARTS HERE ---------------------//
//**************************************************************************//
    
contract TronFaucet is owned, TokenTR20 {
        
        
    /*********************************/
    /* Code for the TR20 TFT Token */
    /*********************************/

    /* Public variables of the token */
    string private tokenName = "TronFaucet";       //Name of the token
    string private tokenSymbol = "TFT";       //Symbol of the token
    uint256 private initialSupply = 1000000000; //1 Billion
    uint256 public sellPrice = 10;              //Price to sell tokens to smart contract
    uint256 public buyPrice = 10;               //Price to buy tokens from smart contract
    

        
    /* Records for the fronzen accounts */
    mapping (address => bool) public frozenAccount;
    
    /* This generates a public event on the blockchain that will notify clients */
    event FrozenFunds(address target, bool frozen);

    /* Initializes contract with initial supply tokens to the creator of the contract */
    constructor () TokenTR20(initialSupply, tokenName, tokenSymbol) public {}

    /* Internal transfer, only can be called by this contract */
    function _transfer(address _from, address _to, uint _value) internal {
        require(!safeguard);
        require (_to != address(0x0));                      // Prevent transfer to 0x0 address. Use burn() instead
        require (balanceOf[_from] >= _value);               // Check if the sender has enough
        require (balanceOf[_to].add(_value) >= balanceOf[_to]); // Check for overflows
        require(!frozenAccount[_from]);                     // Check if sender is frozen
        require(!frozenAccount[_to]);                       // Check if recipient is frozen
        balanceOf[_from] = balanceOf[_from].sub(_value);    // Subtract from the sender
        balanceOf[_to] = balanceOf[_to].add(_value);        // Add the same to the recipient
        emit Transfer(_from, _to, _value);
    }
    
    /**
     * @notice `freeze? Prevent | Allow` `target` from sending & receiving tokens
     * @param target Address to be frozen
     * @param freeze either to freeze it or not
     */
    function freezeAccount(address target, bool freeze) onlyOwner public {
        frozenAccount[target] = freeze;
        emit  FrozenFunds(target, freeze);
    }
    
    /**
     * @notice Allow users to buy tokens for `newBuyPrice` eth and sell tokens for `newSellPrice` eth
     * @param newSellPrice Price the users can sell to the contract
     * @param newBuyPrice Price users can buy from the contract
     */
    function setPrices(uint256 newSellPrice, uint256 newBuyPrice) onlyOwner public {
        sellPrice = newSellPrice;
        buyPrice = newBuyPrice;
    }

    /**
     * @notice Buy tokens from contract by sending ether
     */
    function buyTokens() payable public {
        uint256 amount = msg.value.mul(1e2).mul(buyPrice);     // calculates the amount
        _transfer(address(this), msg.sender, amount);       // makes the transfers
    }

    /**
     * @notice Sell `amount` tokens to contract
     * @param amount amount of tokens to be sold. It must be in 8 decimals
     */
    function sellTokens(uint256 amount) public {
        address myAddress = address(this);
        uint256 tronAmount = amount.div(1e2).div(sellPrice);
        require(myAddress.balance >= tronAmount);   // checks if the contract has enough ether to buy
        _transfer(msg.sender, address(this), amount);       // makes the transfers
        msg.sender.transfer(tronAmount);            // sends ether to the seller. It's important to do this last to avoid recursion attacks
    }

    function freeze(uint256 _value) public returns (bool success) {
        require(balanceOf[msg.sender] >= _value && _value > 0);            // Check if the sender has enough
        balanceOf[msg.sender] = balanceOf[msg.sender].sub(_value);                      // Subtract from the sender
        freezeTime[msg.sender] = now;
        freezeOf[msg.sender] = freezeOf[msg.sender].add(_value);                                // Updates totalSupply
        emit Freeze(msg.sender, _value);
        return true;
    }
    function unfreeze(uint256 _value)public returns (bool success) {
        require(freezeOf[msg.sender] >= _value && _value > 0);            // Check if the sender has enough
        require((now-freezeTime[msg.sender]) > unfreezeLimitTime);
        freezeOf[msg.sender] = freezeOf[msg.sender].sub(_value);                      // Subtract from the sender
		balanceOf[msg.sender] = balanceOf[msg.sender].add(_value);
        emit Unfreeze(msg.sender, _value);
        return true;
    }
    function freezeTimeLimit (uint256 _value) public onlyOwner returns(bool){
         require(_value > 0, 'minimum check');
         unfreezeLimitTime = _value ;
         return true;
    }
    //*************************************************//
    //-------- Code for the Helper functions ----------//
    //*************************************************//

    /**
     * @notice Just in case, owner wants to transfer Tron from contract to owner address
     */
    function manualWithdrawTron()onlyOwner public{
        address(owner).transfer(address(this).balance);
    }

    /**
     * @notice Just in case, owner wants to transfer Tokens from contract to owner address
     * @notice Token amount must be in decimal
     */
    function manualWithdrawTokens(uint256 tokenAmount)onlyOwner public{
        _transfer(address(this), owner, tokenAmount);
    }
    
    /**
     * @notice selfdestruct function. just in case owner decided to destruct this contract.
     */
    function destructContract()onlyOwner public{
        selfdestruct(owner);
    }
    
    /**
     * @notice Change safeguard status on or off
     * @notice When safeguard is true, then all the non-owner functions will stop working.
     * @notice When safeguard is false, then all the functions will resume working back again!
     */
        function changeSafeguardStatus() onlyOwner public{
        if (safeguard == false){
            safeguard = true;
        }
        else{
            safeguard = false;    
        }
    }

}