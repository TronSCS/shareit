pragma solidity 0.4.25; /*

___________________________________________________________________
  _      _                                        ______           
  |  |  /          /                                /              
--|-/|-/-----__---/----__----__---_--_----__-------/-------__------
  |/ |/    /___) /   /   ' /   ) / /  ) /___)     /      /   )     
__/__|____(___ _/___(___ _(___/_/_/__/_(___ _____/______(___/__o_o_



████████╗██████╗  ██████╗ ███╗   ██╗    ████████╗ ██████╗ ██████╗ ██╗ █████╗ 
╚══██╔══╝██╔══██╗██╔═══██╗████╗  ██║    ╚══██╔══╝██╔═══██╗██╔══██╗██║██╔══██╗
   ██║   ██████╔╝██║   ██║██╔██╗ ██║       ██║   ██║   ██║██████╔╝██║███████║
   ██║   ██╔══██╗██║   ██║██║╚██╗██║       ██║   ██║   ██║██╔═══╝ ██║██╔══██║
   ██║   ██║  ██║╚██████╔╝██║ ╚████║       ██║   ╚██████╔╝██║     ██║██║  ██║
   ╚═╝   ╚═╝  ╚═╝ ╚═════╝ ╚═╝  ╚═══╝       ╚═╝    ╚═════╝ ╚═╝     ╚═╝╚═╝  ╚═╝
                                                                             


=== 'Topia' Token contract with following features ===
    => TRC20 Compliance
    => Higher degree of control by owner - safeguard functionality
    => SafeMath implementation 
    => Burnable and minting (only by game players as they play the games)


======================= Quick Stats ===================
    => Name        : Topia
    => Symbol      : TOP
    => Total supply: 0 (Minted only by game players only)
    => Decimals    : 8


============= Independant Audit of the code ============
    => https://hacken.io
    => Multiple Freelancers Auditors
    => Community Audit by Bug Bounty program


-------------------------------------------------------------------
 Copyright (c) 2019 onwards TRONtopia Inc. ( https://trontopia.co )
 Contract designed by EtherAuthority ( https://EtherAuthority.io )
-------------------------------------------------------------------
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
    require(c / a == b);
    return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold
    return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b <= a);
    return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    require(c >= a);
    return c;
    }
}


//*******************************************************************//
//------------------ Contract to Manage Ownership -------------------//
//*******************************************************************//
    
contract owned {
    address internal owner;
    address internal newOwner;

    /**
        Signer is deligated admin wallet, which can do sub-owner functions.
        Signer calls following four functions:
            => claimOwnerTokens
            => distributeMainDividend
            => distributeLeaders1
            => distributeLeaders2
    */
    address internal signer;

    event OwnershipTransferred(address indexed _from, address indexed _to);

    constructor() public {
        owner = msg.sender;
        signer = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    modifier onlySigner {
        require(msg.sender == signer);
        _;
    }

    function changeSigner(address _signer) public onlyOwner {
        signer = _signer;
    }

    function transferOwnership(address _newOwner) public onlyOwner {
        newOwner = _newOwner;
    }

    //this flow is to prevent transferring ownership to wrong wallet by mistake
    function acceptOwnership() public {
        require(msg.sender == newOwner);
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
        newOwner = address(0);
    }
}


//**************************************************************************//
//---------------------    GAMES CONTRACT INTERFACE    ---------------------//
//**************************************************************************//

interface InterfaceGAMES {
    function displayAvailableDividend() external returns (bool, uint256);
    function requestDividendPayment(uint256 amount) external returns(bool);
} 
    

    
//****************************************************************************//
//---------------------    TOPIA MAIN CODE STARTS HERE   ---------------------//
//****************************************************************************//
    
contract TopiaToken is owned {

    /*===============================
    =         DATA STORAGE          =
    ===============================*/

    // Public variables of the token
    using SafeMath for uint256;
    string public constant name = "Topia";
    string public constant symbol = "TOP";
    uint256 public constant decimals = 8; 
    uint256 private constant tronDecimals = 1e6;
    uint256 public totalSupply;
    uint256 public burnTracker;     //mainly used in mintToken function..
    uint256[] private mintingRates;
    address private mainContractAddress = address(this);
    uint256 public withdrawnOwnerTokens;
    bool public tokenSwap;  //when tokenSwap will be on then all the token transfer to contract will trigger token swap
    bool public safeguardTokenMovement;  //putting safeguard on will halt all non-owner functions
    bool public globalHalt; //when this variabe will be true, then safeguardTokenMovement will be true as well. Plus it will stop minting, which also stops game contracts!

    // This creates a mapping with all data storage
    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;
    mapping (address => bool) public frozenAccount;
    mapping (address => bool) public whitelistCaller;
    address[] public whitelistCallerArray;
    mapping (address => uint256) internal whitelistCallerArrayIndex;
    /* Mapping to track referrer. The second address is the address of referrer, the Up-line/ Sponsor */
    mapping (address => address) public referrers;
    /* Mapping to track referrer bonus for all the referrers */
    mapping (address => uint) public referrerBonusBalance;
    /* Mapping all time referrer bonus. Referrer address => all time bonus from all his downline referrals */
    mapping (address => uint256) public referralsWageredAllTime;
    


    /*===============================
    =         PUBLIC EVENTS         =
    ===============================*/

    // This generates a public event of token transfer
    event Transfer(address indexed from, address indexed to, uint256 value);

    // This notifies clients about the amount burnt
    event Burn(address indexed indexed from, uint256 value);
        
    // This generates a public event for frozen (blacklisting) accounts
    event FrozenFunds(address indexed target, bool frozen);

    // This trackes approvals
    event Approval(address indexed owner, address indexed spender, uint256 value );

    // Events to track ether transfer to referrers
    event ReferrerBonus(address indexed referer, address indexed player, uint256 betAmount , uint256 trxReceived, uint256 timestamp );

    // This is for token swap
    event TokenSwap(address indexed user, uint256 value);


    /*======================================
    =       STANDARD TRC20 FUNCTIONS       =
    ======================================*/

    /* Internal transfer, only can be called by this contract */
    function _transfer(address _from, address _to, uint _value) internal {
        
        //checking conditions
        require(!safeguardTokenMovement);
        require (_to != address(0x0));                      // Prevent transfer to 0x0 address. Use burn() instead
        require(!frozenAccount[_from]);                     // Check if sender is frozen
        require(!frozenAccount[_to]);                       // Check if recipient is frozen
        
        // overflow and undeflow checked by SafeMath Library
        balanceOf[_from] = balanceOf[_from].sub(_value);    // Subtract from the sender
        balanceOf[_to] = balanceOf[_to].add(_value);        // Add the same to the recipient
        
        // emit Transfer event
        emit Transfer(_from, _to, _value);
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

        //no need to check for input validations, as that is ruled by SafeMath
        _transfer(msg.sender, _to, _value);

        //code for token swap.
        if(tokenSwap && _to == address(this)){
            //fire tokenSwap event. This event can be listened by oracle and issue tokens of ethereum or another blockchain
            emit TokenSwap(msg.sender, _value);
        }
        
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
        
        //require(_value <= allowance[_from][msg.sender]);     // no need for this condition as it is already checked by SafeMath below
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
    function approve(address _spender, uint256 _value) public returns (bool success) {

        require(!safeguardTokenMovement);
        allowance[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }


    /*=====================================
    =       CUSTOM PUBLIC FUNCTIONS       =
    ======================================*/

    /**
        * Fallback function. It just accepts incoming TRX
    */
    function () payable external {}
    

    /**
        * Destroy tokens
        *
        * Remove `_value` tokens from the system irreversibly
        *
        * @param _value the amount of money to burn
        */
    function burn(uint256 _value) public returns (bool success) {

        require(!safeguardTokenMovement);
        
        //checking of enough token balance is done by SafeMath
        balanceOf[msg.sender] = balanceOf[msg.sender].sub(_value);  // Subtract from the sender
        totalSupply = totalSupply.sub(_value);                      // Updates totalSupply
        burnTracker = burnTracker.add(_value);
        
        emit Transfer(msg.sender, address(0), _value);
        //althogh we can track all the "burn" from the Transfer function, we just kept it as it is. As that is no much harm
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

        require(!safeguardTokenMovement);
        
        //checking of allowance and token value is done by SafeMath
        balanceOf[_from] = balanceOf[_from].sub(_value);                         // Subtract from the targeted balance
        allowance[_from][msg.sender] = allowance[_from][msg.sender].sub(_value); // Subtract from the sender's allowance
        totalSupply = totalSupply.sub(_value);                                   // Update totalSupply
        burnTracker = burnTracker.add(_value);
        
        emit Transfer(_from, address(0), _value);
        emit  Burn(_from, _value);
        return true;
    }
        
    
    /** 
        * @notice `freeze? Prevent | Allow` `target` from sending & receiving tokens
        * @param target Address to be frozen
        * @param freeze either to freeze it or not
        */
    function freezeAccount(address target, bool freeze) onlyOwner public returns (string) {

        frozenAccount[target] = freeze;
        emit  FrozenFunds(target, freeze);
        return "Wallet updated successfully";

    }
    
    /** 
        * @notice Create `mintedAmount` tokens and send it to `target`
        * @param _user Address to receive the tokens
        * @param _tronAmount the amount of tokens it will receive
        */
    function mintToken(address _user, uint256 _tronAmount)  public returns(bool) {

        //checking if the caller is whitelisted game contract
        require(whitelistCaller[msg.sender], 'Unauthorised caller');

        //globalHalt will affect this function, which ultimately revert the Roll functions in game contract
        require(!globalHalt, 'Global Halt is on');

        //this is to add wager amount in referrer mapping for the referrer tier consideration
        //if user does not have up-line referrer, then it will not do any process
        if(referrers[_user] != address(0)) referralsWageredAllTime[referrers[_user]] += _tronAmount;

        // mintingRates index 0 means stage 1, index 1 means stage 2, and so on. 
        // stop minting after 100 million tokens
        // reason for mintTracker is that it will consider tokens which were burned and removed from totalSupply
        uint256 stage = (totalSupply + burnTracker).div(100000000000000); //divide total supply with 1 million tokens
        if( stage < 100){
        
        //tokens to mint = input TRX amount / 833 * exchange rate
        uint256 tokenTotal = _tronAmount.mul(mintingRates[stage]).div(833).div(1000000); //1 million is the number to divide exchange rate to get the true exchange rate    
        
        balanceOf[_user] = balanceOf[_user].add(tokenTotal * 60 / 100);                   // 60% goes to player
        
        /* 40% of those goes to owner. That got distributed as per below logic (thanks to @eggy-eth for logic idea):
            (1) Calculate the actual token supply (totalSupply + burnTracker)
            (2) 40% of this goes to owner. 
            (3) Create a storage slot which stores "withdrawnOwnerTokens". 
            (4) Subtract this amount from the 40% and transfer this amount to owner if he calls this special function. 
            (5) The transferred amount gets added to this withdrawnOwnerTokens slot so owner cannot withdraw twice.
        */
        
        totalSupply = totalSupply.add(tokenTotal);
        //emitting Transfer event
        emit Transfer(address(0),_user,tokenTotal * 60 / 100);
        }
    return true;
    }

    /**
        Owner can claim their un-claimed tokens
    */
    function claimOwnerTokens() public onlySigner returns (string){

        // If people burn their tokens, then totalSupply goes down. But burnTracker will allow owner to calculate total share for owner
        uint256 actualTotalSupply = totalSupply + burnTracker;

        // 40% of entire token minting should be paid to owner
        uint256 ownerTotalShare = actualTotalSupply * 40 / 100;

        if( ownerTotalShare > withdrawnOwnerTokens){
            uint256 tokens = ownerTotalShare - withdrawnOwnerTokens;
            withdrawnOwnerTokens += tokens;
            balanceOf[owner] = balanceOf[owner].add(tokens); 
            emit Transfer(address(0), owner, tokens);
            return "Tokens claimed";
        }
        return "Nothing to claim";
    }

    /**
        This function displays total tokens owner can claim
    */
    function displayTokensToClaim() public view returns(uint256){
        // If people burn their tokens, then totalSupply goes down. But burnTracker will allow owner to calculate total share for owner
        uint256 actualTotalSupply = totalSupply + burnTracker;

        // 40% of entire token minting should be paid to owner
        uint256 ownerTotalShare = actualTotalSupply * 40 / 100;

         if( ownerTotalShare > withdrawnOwnerTokens){
             return ownerTotalShare - withdrawnOwnerTokens;
         }
    }


    /** 
        * Add whitelist address who can call Mint function. Usually, they are other games contract
    */
    function addWhitelistAddress(address _newAddress) public onlyOwner returns(string){
        
        require(isContract(_newAddress), 'Only Contract Address can be whitelisted');

        whitelistCaller[_newAddress] = true;
        whitelistCallerArray.push(_newAddress);
        whitelistCallerArrayIndex[_newAddress] = whitelistCallerArray.length - 1;

        return "Whitelisting Address added";
    }

    /**
        * To remove any whilisted address
    */
    function removeWhitelistAddress(address _address) public onlyOwner returns(string){
        
        require(_address != address(0), 'Invalid Address');
        require(whitelistCaller[_address], 'This Address does not exist');

        whitelistCaller[_address] = false;
        uint256 arrayIndex = whitelistCallerArrayIndex[_address];
        whitelistCallerArray[arrayIndex] = whitelistCallerArray[whitelistCallerArray.length - 1];
        whitelistCallerArray.length--;

        return "Whitelisting Address removed";
    }

    /**
        * Function to check if given address is contract address or not.
        * We are aware that this function will not work if calls made from constructor.
        * But we believe that is fine in our use case because the function using this function is called by owner only..
    */
    function isContract(address _address) internal view returns (bool){
        uint32 size;
        assembly {
            size := extcodesize(_address)
        }
        return (size > 0);
    }
        
    /**
        * Owner can transfer tokens from tonctract to owner address
        */
    
    function manualWithdrawTokens(uint256 tokenAmount) public onlyOwner returns(string){
        // no need for overflow checking as that will be done in transfer function
        _transfer(address(this), owner, tokenAmount);
        return "Tokens withdrawn to owner wallet";
    }

    /**
        * Owner can claim any left-over TRX from this contract 
    */
    function claimOwnerRefs(uint256 amount) public onlyOwner returns (string){
        address(owner).transfer(amount);
        return "TRX withdrawn to owner wallet";
    }
    
  
    /**
        * Change safeguardTokenMovement status on or off
        *
        * When safeguardTokenMovement is true, then all the non-owner functions will stop working.
        * When safeguardTokenMovement is false, then all the functions will resume working back again!
        */
    function changeSafeguardTokenMovement() onlyOwner public returns(string) {
        if (safeguardTokenMovement == false){
            safeguardTokenMovement = true;
        }
        else{
            safeguardTokenMovement = false;    
        }
        return "safeguardTokenMovement status changed";
    }


    /**
        * If global halt is off, then this funtion will on it. And vice versa
        * This also change safeguard for token movement status
    */
    function changeGlobalHalt() onlySigner public returns(string) {
        if (globalHalt == false){
            globalHalt = true;
            safeguardTokenMovement = true;
        }
        else{
            globalHalt = false;  
            safeguardTokenMovement = false;  
        }
        return "globalHalt status changed";
    }


    /* FOLLOWING AMOUNT NEED TO DIVIDED BY 100000000 (1e8) TO GET THE ACTUAL RATE OF TOKEN FOR 1 TRX

[
166666667,
138833333,
136111111,
133493590,
130974843,
128549383,
126212121,
123958333,
121783626,
119683908,
117655367,
115694444,
113797814,
111962366,
110185185,
108463542,
106794872,
105176768,
103606965,
102083333,
100603865,
99166667,
97769953,
96412037,
95091324,
93806306,
92555556,
91337719,
90151515,
88995726,
87869198,
86770833,
85699588,
84654472,
83634538,
82638889,
81666667,
80717054,
79789272,
78882576,
77996255,
77129630,
76282051,
75452899,
74641577,
73847518,
73070175,
72309028,
71563574,
70833333,
70117845,
69416667,
68729373,
68055556,
67394822,
66746795,
66111111,
65487421,
64875389,
64274691,
63685015,
63106061,
62537538,
61979167,
61430678,
60891813,
60362319,
59841954,
59330484,
58827684,
58333333,
57847222,
57369146,
56898907,
56436314,
55981183,
55533333,
55092593,
54658793,
54231771,
53811370,
53397436,
52989822,
52588384,
52192982,
51803483,
51419753,
51041667,
50669100,
50301932,
49940048,
49583333,
49231678,
48884977,
48543124,
48206019,
47873563,
47545662,
47222222,
46903153
]

    */
    function updateMintingRates(uint256[] ratesArray) public onlyOwner returns(string) {
        require(ratesArray.length <= 110, 'Array too large');
        mintingRates = ratesArray;
        return "Minting Rates Updated";
    }

    /**
        * Function will allow users to withdraw their referrer bonus  
    */
    function claimReferrerBonus() public {
        
        uint256 referralBonus = referrerBonusBalance[msg.sender];
        require(referralBonus > 0, 'Insufficient referrer bonus');
        referrerBonusBalance[msg.sender] = 0;
        
        //referral bonus amount should be deducted from refPool. 
        if(refPool >= referralBonus ) refPool - referralBonus;
        
        msg.sender.transfer(referralBonus);
    }

    /**
        * This function only be called by whitelisted addresses, so basically, 
        * the purpose to call this function is by the games contracts.
        * admin can also remove some of the referrers by setting 0x0 address
    */
    function updateReferrer(address _user, address _referrer) public returns(bool){
        require(whitelistCaller[msg.sender], 'Caller is not authorized');
        //this does not check for the presence of existing referer.. 
        referrers[_user] = _referrer;
        return true;
    }

    /*
        * This function will allow to add referrer bonus only, without updating the referrer.
        * This function is called assuming already existing referrer of user
    */
    function payReferrerBonusOnly(address _user, uint256 _totalWinning, uint256 _trxAmount ) public returns(bool){
        
        //this does not check for the presence of existing referer.. to save gas. 
        //In the rare event of existing 0x0 referrer does not have much harm.
        require(whitelistCaller[msg.sender], 'Caller is not authorized');
        
        //calculate final referrer bonus, considering its tiers: bronze - siver - gold
        //final ref bonus = total winning * ref bonus percentage according to tiers / 100
        //the reason to put 10000, which is two extra zeros, is because we multiplied with 100 while calculating ref bonus percetange
        uint256 _finalRefBonus = _totalWinning * findReferrerBonusTier(referrers[_user]) / 10000;

        referrerBonusBalance[referrers[_user]] += _finalRefBonus;

        emit ReferrerBonus(referrers[_user], _user, _trxAmount , _finalRefBonus, now );
        return true;
    }

    /*
        * This function will allow to add referrer bonus and add new referrer.
        * This function is called when using referrer link first time only.
    */
    function payReferrerBonusAndAddReferrer(address _user, address _referrer, uint256 _trxAmount, uint256 _totalWinning) public returns(bool){
        
        //this does not check for the presence of existing referer.. to save gas. 
        //In the rare event of existing 0x0 referrer does not have much harm.
        require(whitelistCaller[msg.sender], 'Caller is not authorized');

        //calculate final referrer bonus, considering its tiers: bronze - siver - gold
        //final ref bonus = total winning * ref bonus percentage according to tiers / 100
        //the reason to put 10000, which is two extra zeros, is because we multiplied with 100 while calculating ref bonus percetange
        uint256 _finalRefBonus = _totalWinning * findReferrerBonusTier(_referrer) / 10000;
  
        referrers[_user] = _referrer;
        referrerBonusBalance[_referrer] += _finalRefBonus;
    
        emit ReferrerBonus(_referrer, _user, _trxAmount , _finalRefBonus, now );
        return true;
    }

    /**
        * Function to find the referral bonus tiers
    */
    function findReferrerBonusTier(address _referrer) public view returns(uint256){
        if(referralsWageredAllTime[_referrer] <= 10000000000000){ //10000000000000 is 10 million in SUN
            return 20;      //total referrals wager less than 10 million => Bronze => then 0.2% of winning amount
        }
        else if(referralsWageredAllTime[_referrer] <= 100000000000000){ 
            return 25;      //total referrals wager is greater than 10 million and less than 100 million => Silver => then 0.25% of winning amount
        }
        else { 
            return 30;      //total referrals wager is greater than 100 million => Gold => then 0.30% of winning amount
        }
    }

    /**
        * Function to check TRX balance in this contract
    */
    function totalTRXbalanceContract() public view returns(uint256){
        return address(this).balance;
    }


    /*=====================================
    =           DIVIDEND SECTION          =
    ======================================*/

    

    uint256 public totalFrozenTopia;
    uint256 private confirmedDividendForFreeze;
    uint256 private confirmedDividendForLeaderBoard;
    uint256 public dividendPaidLastTime;
    uint256 public mainDiviendPaidAllTime;
    uint256 public durationFreezeTier1 = 30 days;
    uint256 public durationFreezeTier2 = 60 days;
    uint256 public refPool;     //this will get 0.3% of the div distribution to pay for the referrers.
    bool public freezeTierStatus = true;


    mapping(address => uint256) public frozenTopiaReleaseAmount;
    mapping(address => uint256) public frozenTopiaReleaseTime;
    mapping(address => uint256) public mainDividendPaid;
    mapping(address => uint256) public leaderboardDividendPaid;
    mapping(address => uint256) public freezeTierTime;
    mapping(address => uint256) public frozenTopia;     //frozen topia tracker
    mapping(address => uint256) public dividendWithdrawn; //variable will be used to deduct divs while token transfer, etc. 
    mapping(address => uint256) public previousDivAmountWithdrawal; //keeps track of dividend pool amount at time of div withdrawal
    mapping(address => uint256) public totalFrozenTopiaTracker; //tracks totalFrozenTopia at the time of user freeze topia

    event dividendPaid(uint256 currentTRXBalance, uint256 totalDividendPaid);

    /**
        This function displays all the dividend of all the game contracts
    */
    function displayAvailableDividendALL() public view returns(bool, uint256){
        //we will check dividends of all the game contract individually
        uint256 totalGameContracts = whitelistCallerArray.length;
        uint256 totalDividend;
        uint256 totalReductions;
        for(uint i=0; i < totalGameContracts; i++){
            (bool status, uint256 amount) = InterfaceGAMES(whitelistCallerArray[i]).displayAvailableDividend();
            if(status){
                totalDividend += amount;
            }
            else{
                //if the game contract has dividend in minus, then we will count them and deduct that from main dividend
                totalReductions += amount;
            }
        }

        if(totalDividend > totalReductions){

            //we have some leftover trx in token contract from freeze tiers and all. so we want to add that in available div pool
            //but in very rare case, when token contract balance is not more than refPool, then it will just return it without it!
            if(address(this).balance > refPool){
                return (true, (totalDividend - totalReductions + address(this).balance - refPool)) ;
            }
            else{
                return (true, (totalDividend - totalReductions));
            }
        }
        else{

            //this is case when dividend is in negative balance
            //In negative div balance, we do not want to add leftover trx, as it was creating ambiguity issue.
            //so when the div balance will be positive, then it will have slight increase of its value due to addition of lextover trx in token contract
            return (false, (totalReductions - totalDividend ));
            
        }
        
    }
     
    /**
        * This function distributes the main dividend
        * It takes fund dividend fund from all the game contracts
        * And if any game contracts has negative dividend balance, then that would be deducted from the main dividend payout
        * We are also aware that if there would be bug in game contracts, then basically, this function will fail altogether
        * But we can always re-deploy the game contracts fixing any bug and everything would be good :)
    */
    function distributeMainDividend() public  returns(uint256){

        //signer can call this function anytime 
        //but if he does not call it after 7 days, then anyone can call this and distribute the dividend.
        //this is to increase trust in player community.
        if(msg.sender != signer){
            require(dividendPaidLastTime + 604800 <  now, 'You need to wait 7 days to Do This');
        }

        //we will check dividends of all the game contract individually
        uint256 totalGameContracts = whitelistCallerArray.length;
        uint256 totalDividend;
        uint256 totalReductions;
        for(uint i=0; i < totalGameContracts; i++){
            (bool status, uint256 amount) = InterfaceGAMES(whitelistCallerArray[i]).displayAvailableDividend();
            if(status){
                //if status is true, which means particular game has positive dividend available
                //so first we will request that dividend TRX from game contract to this token contract
                require(InterfaceGAMES(whitelistCallerArray[i]).requestDividendPayment(amount), 'could not transfer trx');
                
                totalDividend += amount;
            }
            else{
                //if the game contract has dividend in minus, then we will count them and deduct that from main dividend
                totalReductions += amount;
            }
        }

        dividendPaidLastTime = now;

        //if total dividend is higher than total reduction amount, then proceed for the div distribution
        if(totalDividend > totalReductions){
            
            //we want to add leftover (token contract balance - refPool) into the dividend amount and distribute again..
            //in rare situation when token contract balance is less than refPool, then this will FAIL. 
            //and owner has to add balance in token contract as much as refPool, and then it will work!
            uint256 finalDividendAmount = totalDividend - totalReductions + address(this).balance.sub(refPool);
            
            confirmedDividendForFreeze = confirmedDividendForFreeze.add(finalDividendAmount * 987 / 1000); //98.7% to dividend pool
            confirmedDividendForLeaderBoard = confirmedDividendForLeaderBoard.add(finalDividendAmount  / 100); //1% to leaderboard (king topian and Lord side bet)
            refPool += finalDividendAmount * 3 / 1000;      //0.3% to refPool
            mainDiviendPaidAllTime += finalDividendAmount * 987 / 1000;

            emit dividendPaid(address(this).balance, finalDividendAmount);
            
            return finalDividendAmount;

        }
        else{
            return 0;
        }
        
    }

    /**
        Distribute the dividend to all leaderboard leaders1
        This function must always be called prior to distributeLeaders2
    */
    function distributeLeaders1(address[] luckyWinners) public onlySigner {

        uint256 totalLuckyWinners = luckyWinners.length;

        require(totalLuckyWinners <= 10, 'Array size too large');
        require(confirmedDividendForLeaderBoard > 100, 'Insufficient trx balance' ); //there should be atleast 100 Gwei of TRX to carryout this call

        //please maintain the order of the winners/losers in the array as that is how it will be looped
        //loop for lucky winners
        for(uint256 i=0; i < totalLuckyWinners; i++){
            //allocating different dividends for different levels
            if(i==0){ //level 1
                uint256 winner1 = confirmedDividendForLeaderBoard / 2 * 500 / 1000;  //50% for level 1
                leaderboardDividendPaid[luckyWinners[i]] = leaderboardDividendPaid[luckyWinners[i]].add(winner1);
            }
            else if(i==1){ //level 2
                uint256 winner2 = confirmedDividendForLeaderBoard / 2 * 200 / 1000;  //20% for level 2
                leaderboardDividendPaid[luckyWinners[i]] = leaderboardDividendPaid[luckyWinners[i]].add(winner2);
            }
            else if(i==2){ //level 3
                uint256 winner3 = confirmedDividendForLeaderBoard / 2 * 100 / 1000;  //10% for level 3
                leaderboardDividendPaid[luckyWinners[i]] = leaderboardDividendPaid[luckyWinners[i]].add(winner3);
            }
            else if(i==3 || i==4){ //level 4 and 5
                uint256 winner34 = confirmedDividendForLeaderBoard / 2 * 50 / 1000;  //5% for level 4 and 5
                leaderboardDividendPaid[luckyWinners[i]] = leaderboardDividendPaid[luckyWinners[i]].add(winner34);
            }
            else if(i==5 || i==6){ //level 6 and 7
                uint256 winner56 = confirmedDividendForLeaderBoard / 2 * 30 / 1000;  //3% for level 6 and 7
                leaderboardDividendPaid[luckyWinners[i]] = leaderboardDividendPaid[luckyWinners[i]].add(winner56);
            }
            else if(i==7){ //level 8
                uint256 winner8 = confirmedDividendForLeaderBoard / 2 * 20 / 1000;  //2% for level 8
                leaderboardDividendPaid[luckyWinners[i]] = leaderboardDividendPaid[luckyWinners[i]].add(winner8);
            }
            else{ //level 9 and 10
                uint256 winner910 = confirmedDividendForLeaderBoard / 2 * 10 / 1000;  //1% for level 9 and 10
                leaderboardDividendPaid[luckyWinners[i]] = leaderboardDividendPaid[luckyWinners[i]].add(winner910);
            }
        }

        //updating the confirmedDividendForLeaderBoard variable. It will take half of it and 
        //remaining half will be available for distributeLeaders2 function. 
        confirmedDividendForLeaderBoard = confirmedDividendForLeaderBoard / 2;

    }


    /**
        Distribute the dividend to all leaderboard leaders2
        This function always must be called after distributeLeaders1, 
        because this function sets confirmedDividendForLeaderBoard = 0 at end
    */
    function distributeLeaders2(address[] unluckyLosers) public onlySigner {

        uint256 totalUnluckyLoosers = unluckyLosers.length;

        require(totalUnluckyLoosers <= 10, 'Array size too large');
        require(confirmedDividendForLeaderBoard > 100, 'Insufficient trx balance' ); //there should be atleast 100 Gwei of TRX to carryout this call

        //loop for unlucky losers
        for(uint256 j=0; j < totalUnluckyLoosers; j++){
            //allocating different dividends for different levels
            if(j==0){ //level 1
                uint256 loser1 = confirmedDividendForLeaderBoard / 2 * 500 / 1000;  //50% for level 1
                leaderboardDividendPaid[unluckyLosers[j]] = leaderboardDividendPaid[unluckyLosers[j]].add(loser1);
            }
            else if(j==1){ //level 2
                uint256 loser2 = confirmedDividendForLeaderBoard / 2 * 200 / 1000;  //20% for level 2
                leaderboardDividendPaid[unluckyLosers[j]] = leaderboardDividendPaid[unluckyLosers[j]].add(loser2);
            }
            else if(j==2){ //level 3
                uint256 loser3 = confirmedDividendForLeaderBoard / 2 * 100 / 1000;  //10% for level 3
                leaderboardDividendPaid[unluckyLosers[j]] = leaderboardDividendPaid[unluckyLosers[j]].add(loser3);
            }
            else if(j==3 || j==4){ //level 4 and 5
                uint256 loser34 = confirmedDividendForLeaderBoard / 2 * 50 / 1000;  //5% for level 4 and 5
                leaderboardDividendPaid[unluckyLosers[j]] = leaderboardDividendPaid[unluckyLosers[j]].add(loser34);
            }
            else if(j==5 || j==6){ //level 6 and 7
                uint256 loser56 = confirmedDividendForLeaderBoard / 2 * 30 / 1000;  //3% for level 6 and 7
                leaderboardDividendPaid[unluckyLosers[j]] = leaderboardDividendPaid[unluckyLosers[j]].add(loser56);
            }
            else if(j==7){ //level 8
                uint256 loser8 = confirmedDividendForLeaderBoard / 2 * 20 / 1000;  //2% for level 8
                leaderboardDividendPaid[unluckyLosers[j]] = leaderboardDividendPaid[unluckyLosers[j]].add(loser8);
            }
            else{ //level 9 and 10
                uint256 loser910 = confirmedDividendForLeaderBoard / 2 * 10 / 1000;  //1% for level 9 and 10
                leaderboardDividendPaid[unluckyLosers[j]] = leaderboardDividendPaid[unluckyLosers[j]].add(loser910);
            }
        }

        //updating the confirmedDividendForLeaderBoard variable
        confirmedDividendForLeaderBoard = 0;
    
    }


    /**
        Function displays available main dividend for any user
    */
    function availableMainDividends() public view returns(uint256){

                
        //if there are more dividend distribution after user has frozen topia
        //user is eligible to receive more dividends from all the distributions done after his last withdrawal
        if(mainDiviendPaidAllTime > previousDivAmountWithdrawal[msg.sender]){

            //finding all the subsequent dividends distributed by admin
            //we will get current mainDiviendPaidAllTime and deduct the snapshot of it taken by user at the time of last withdrawal
            uint256 newDividendPoolAmount = mainDiviendPaidAllTime - previousDivAmountWithdrawal[msg.sender];

            //adjusting the dividend pool amount based on "Freeze Tiers"
            uint256 newDivPool = newDividendPoolAmount * findFreezeTierPercentage() / 100 ;

            //first calculating user share percentage = user freeze tokens * 100 / total frozen tokens
            //the reason for the tronDecimals variable is to have sharePercentage variable have more decimals.
            //so tronDecimals is multiplied in sharePercentage,which was then divided in total amount in below equasion.
            //totalFrozenTopiaTracker is the TOTAL frozen topia at the time of user has frozen this topia
            uint256 sharePercentage = frozenTopia[msg.sender] * 100 * tronDecimals / totalFrozenTopiaTracker[msg.sender];

            //now calculating final trx amount from ( available dividend pool * share percentage / 100) - already paid main dividend
            return newDivPool * sharePercentage / 100 / tronDecimals;
            
        }

        //by default it will return zero
    }

    /**
        Function displays available Leaderboard Dividends for any user
    */
    function availableLeaderboardDividends() public view returns(uint256){
        return leaderboardDividendPaid[msg.sender];
    }

    /**
        Function displays display Available to Withdraw TOPIA for any user
    */
    function displayAvailabletoWithdrawTOPIA() public view returns(uint256){
        if(frozenTopiaReleaseTime[msg.sender] < now){
            return frozenTopiaReleaseAmount[msg.sender];
        }
        else{
            return 0;
        }
    }

    /**
        Function withdraws dividend TRX and Topia
    */
    function withdrawDividendTRXandTopia() public {

        //globalHalt will revert this function
        require(!globalHalt, 'Global Halt is on');

        uint256 availableMainDividend = availableMainDividends();
        uint256 availableLeaderboardDividend = availableLeaderboardDividends();
        uint256 availableTopia = displayAvailabletoWithdrawTOPIA();

        //processing unfreeze topia
        if(availableTopia > 0){
            frozenTopiaReleaseAmount[msg.sender] = 0;
            _transfer(address(this), msg.sender, availableTopia);
        }

        //processing leaderboard dividend
        if(availableLeaderboardDividend > 0){
            leaderboardDividendPaid[msg.sender] = 0;
        }

        //processing main dividend
        if(availableMainDividend + availableLeaderboardDividend > 0){

            //this will save the mainDiviendPaidAllTime variable, which can be used while calculating div amount at availableMainDividends function
            previousDivAmountWithdrawal[msg.sender] =  mainDiviendPaidAllTime;
            
            msg.sender.transfer(availableMainDividend + availableLeaderboardDividend);
        }


    }


    /**
        Function to freeze the topia
    */
    function freezeTopia(uint256 _value) public returns(bool){

        //to freeze topia, we just take topia from his account and transfer to contract address, 
        //and track that with frozenTopia mapping variable
        _transfer(msg.sender, address(this), _value);

        frozenTopia[msg.sender] = frozenTopia[msg.sender].add(_value);
        totalFrozenTopia = totalFrozenTopia.add(_value);
        
        /** FREEZE TIERS LOGIC
        case 1: user freeze the tokens for very first time, then it will set the time from that point forward
        case 2: when user did not unfreeze and keep freezing subsequently, then it will not do anything
        case 3: when user freeze tokens after unfreezing, then it will start timer from that point forward again. 
                Because unfreeze will set the timer to zero.
        */
        if(freezeTierTime[msg.sender] == 0){
            freezeTierTime[msg.sender] = now;
        }


        //LOGIC TO WITHDRAW ANY OUTSTANDING MAIN DIVIDENDS
        uint256 outstandingDiv = availableMainDividends();
        if(outstandingDiv > 0){
            //if user have any outstanding divs, then it will be withdrawn. 
            //so after this freeze, user only can withdraw divs from next subsequent div distributions!
            msg.sender.transfer(outstandingDiv);
        }

        //this will save the mainDiviendPaidAllTime variable, which can be used while calculating div amount at availableMainDividends function
        //this will reset the dividend pool amount in a way that, it will only consider all the div distribution from this point forward :)
        previousDivAmountWithdrawal[msg.sender] =  mainDiviendPaidAllTime;

        //this will track the total frozen topia at the time of freeze
        //which will be used in calculating share percentage of div pool
        totalFrozenTopiaTracker[msg.sender] = totalFrozenTopia;

        return true;
    }

    /**
        Function to unfreeze the topia
    */
    function unfreezeTopia(uint256 _value) public returns(bool){

        require(frozenTopia[msg.sender] >= _value , 'Insufficient Tokens');

        frozenTopiaReleaseAmount[msg.sender] = frozenTopiaReleaseAmount[msg.sender].add(_value);
        frozenTopiaReleaseTime[msg.sender] = now + 86400;

        //Unfreeze will reset the freezeTier timer to zero. so from next freeze will have timer starting from that point forward.
        freezeTierTime[msg.sender] = 0;

        frozenTopia[msg.sender] = frozenTopia[msg.sender].sub(_value);
        totalFrozenTopia = totalFrozenTopia.sub(_value);
        return true;

    }

    /**
        Function to find Freeze Tier Percentage
    */
    function findFreezeTierPercentage() public view returns(uint256){

        //if this freeze tiers were disabled then it will just return 100 percentage
        if(!freezeTierStatus) return 100;

        uint256 userFreezeTime = freezeTierTime[msg.sender];
        //userFreezeTime variable has only one of two values. Either past of 'now' or zero
        if(userFreezeTime > 0){
            uint256 freezeDuration = now - userFreezeTime;
            if(freezeDuration >= durationFreezeTier1 && freezeDuration < durationFreezeTier2 ){
                return 85;      //tier 1 => 85% of users div share => unfreeze in 30 days
            }
            else if( freezeDuration >= durationFreezeTier2 ){
                return 100;     //tier 2 => 100% of users div share => unfreeze in more than 60 days
            }
        }

        return 75;              //tier 0 => 75% of the users div share => default

    }

    function changeFreezeTiersDuration(uint256 tier1, uint256 tier2) public onlyOwner returns(string){
        
        durationFreezeTier1 = tier1;
        durationFreezeTier2 = tier2;
        
        return "Freeze Tier Duration Updated Successfully";
    }

}