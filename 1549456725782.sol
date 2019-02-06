pragma solidity ^0.4.25;

// safeMath library //
library SafeMath {

    function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
        if (a == 0) {
            return 0;
        }

        c = a * b;
        assert(c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }
    
    function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
        c = a + b;
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
    
//**************************************************************************//
//---------------------  TRONTOPIA MAIN CODE STARTS HERE ---------------------//
//**************************************************************************//

contract TronTopia is owned{
    /* Public variables of the token */
    string public name;
    string public symbol;
    string private tokenName = "Topia";       //Name of the token
    string private tokenSymbol = "TOP";       //Symbol of the token
    uint256 private initialSupply = 1000000000; //1 Billion
    uint256 public sellPrice = 10;              //Price to sell tokens to smart contract
    uint256 public buyPrice = 10;               //Price to buy tokens from smart contract
    using SafeMath for uint256;
    uint256[] public multipliersData;
    uint256 public decimals = 8; 
    uint256 public totalSupply;
    bool public safeguard = false;  //putting safeguard on will halt all non-owner functions
    uint256 nonce = 0;
    address private mainContractAddress = address(this);
        
    
    /* Records for the fronzen accounts */
    mapping (address => bool) public frozenAccount;
    // This creates an array with all balances
    mapping (address => uint256) public balanceOf;

     /* Mapping to track referrer. The second address is the address of referrer, the Up-line/ Sponsor */
    mapping (address => address) public referrers;

    /* Mapping to track referrer bonus for all the referrers */
    mapping (address => uint) public referrerBonusBalance;
    
    // This generates a public event on the blockchain that will notify clients
    event Transfer(address indexed from, address indexed to, uint256 value);

    /* This generates a public event on the blockchain that will notify clients */
    event FrozenFunds(address target, bool frozen);

    /* Events to track ether transfer to referrers */
    event ReferrerBonus(address indexed referer, address indexed player, uint256 betAmount , uint256 trxReceived, uint256 timestamp );

    /* Initializes contract with initial supply tokens to the creator of the contract */
     constructor (
        uint256 initialSupply,
        string memory tokenName,
        string memory tokenSymbol
    ) public {
        totalSupply = initialSupply.mul(10**decimals);          // Update total supply with the decimal amount
        balanceOf[mainContractAddress] = totalSupply;           //100% will assign in contract
      
        name = tokenName;                                       // Set the name for display purposes
        symbol = tokenSymbol;                                   // Set the symbol for display purposes
        
        emit Transfer(address(0), mainContractAddress, totalSupply);
    }
    
    event Roll(address indexed user, uint _startNumber, uint _endNumber, uint _winningNumber, uint256 _value, bool result,uint256 timestamp);
    
    /*generate random hash seed */
    function getSeed() public view returns(bytes32){
        return sha256(now);
    }
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
    }
    
    /* Function will allow users to withdraw their referrer bonus  */
    function claimReferrerBonus() public {
        uint256 referralBonus = referrerBonusBalance[msg.sender];
        require(referralBonus > 0, 'Insufficient referrer bonus');
        referrerBonusBalance[msg.sender] = 0;
        msg.sender.transfer(referralBonus);
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

    /*********************************/
    /*  Code for Main TronTopia Game   */
    /*********************************/
    
    //--- Public variables of the PlaceIt -------------//
    uint internal tronDecimals=6;
    uint256 public betPrice = 10 * (10**tronDecimals);                   //10 TRX for 1 bet
    uint256 public communityPoolVolume = 0;                            //Total TRX accumulated for commuinty pool for any given round
    uint256 public TotalBetsMade =0;
    uint256 public minimumTokenRequirement = 100 * (10**decimals);     //User must have at least 100 Tokens to be eligible to receive winnings
    uint256 public poolMinimumRequirement = 1000000 * (10**tronDecimals);  //1 Million

    
    //--- Data storage variables -----------------------//
    
    
   // mapping(bytes32=>uint256) TotalBetsMade;     //Mapping holds purchase volume for each community
    
    
    //addMultiplier to store multiplier array data in contract
    function addMultiplier (uint256[] memory data) public onlyOwner returns(string){
        multipliersData = data;
        return "Multiplyer Added";
    }
  
    //function to roll dice and win or loose game
    function roll(uint _startNumber,uint _endNumber,uint _amount, bytes32 _seed, address _referrer) payable public returns(bool,uint256) {
            require(_startNumber >0, 'Invalid _startNumber');
            require(_endNumber >0, 'Invalid _endNumber');
            require(_amount >0, 'Invalid _amount');
            require(_seed !=bytes32(0), 'Invalid _seed');
            TotalBetsMade++;
            uint _winningNumber = random(_seed);
            if(_winningNumber>=_startNumber && _winningNumber<=_endNumber){
                
                uint256 multiplier = multipliersData[_winningNumber--];
                uint256 winamount = _amount.mul(multiplier);
               
                uint _refBonus;
                // [✓] 0.2% trx to referral if any.
                /** Processing referral system fund distribution **/
                // Case 1: player have used referral links
                if(_referrer != address(0x0) && referrers[msg.sender] != address(0x0)){
                    _refBonus = winamount.mul(2).div(1000);
                    referrerBonusBalance[referrers[msg.sender]] += _refBonus;  //0.2% of winamount
                    winamount = winamount.sub(_refBonus);
                    emit ReferrerBonus(referrers[msg.sender], msg.sender, msg.value , _refBonus, now );
                }
                
                // Case 2: player has existing referrer/up-line/direct sponsor, but he did not use any referrer link or sent trx directly to smart contract
                // In this case, trx will be sent to existing referrer
                else if(_referrer == address(0x0) && referrers[msg.sender] != address(0x0)){
                    _refBonus = winamount.mul(2).div(1000);
                    referrerBonusBalance[referrers[msg.sender]] += _refBonus;  //0.2% of winamount 
                    winamount = winamount.sub(_refBonus);
                    emit ReferrerBonus(referrers[msg.sender], msg.sender, msg.value , _refBonus, now );
                }
                

                // Case 3: depositor does not have any existing direct referrer, but used referral link
                // In this case, referral bonus will be paid to address in the referral link
                else if(_referrer != address(0x0) && referrers[msg.sender] == address(0x0)){
                    _refBonus = winamount.mul(2).div(1000);
                    referrerBonusBalance[_referrer] += _refBonus;  //0.2% of winamount 
                    winamount = winamount.sub(_refBonus);
                    emit ReferrerBonus(_referrer, msg.sender, msg.value , _refBonus, now );
                   
                    //adding referral details in both the mappings
                    referrers[msg.sender]=_referrer;
                }
                
                // All other cases apart from above, referral bonus will not be paid to anyone
                // And Entire platform fee (5% of deposit) will be sent to stock contract
                else {
                    winamount = winamount;
                }
                
                balanceOf[msg.sender] = balanceOf[msg.sender].add(winamount);
                emit Roll(msg.sender,_startNumber, _endNumber, _winningNumber, _amount, true, now);
                return (true,_winningNumber);
            }else{
                 communityPoolVolume+=_amount;
                if(_referrer != address(0x0) && referrers[msg.sender] == address(0x0)){ 
                    //adding referral details in both the mappings
                    referrers[msg.sender]=_referrer;
                }
                 emit Roll(msg.sender, _startNumber, _endNumber, _winningNumber, _amount, false, now);
                 return (false,_winningNumber);
            }
    }
    //function to generate random number
    function random(bytes32 seed) internal returns (uint) {
            uint randomnumber = uint(keccak256(abi.encodePacked(now, msg.sender, nonce, seed))) % 99;
            randomnumber = randomnumber + 1;
            nonce++;
            return randomnumber;
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