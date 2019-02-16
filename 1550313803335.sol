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
    uint256 private initialSupply = 0;          //0 
    uint256 public sellPrice = 10;              //Price to sell tokens to smart contract
    uint256 public buyPrice = 10;               //Price to buy tokens from smart contract
    using SafeMath for uint256;
    uint256[] public multipliersData;
    uint256 public decimals = 8; 
    uint256 public totalSupply;
    bool public safeguard = false;  //putting safeguard on will halt all non-owner functions
    uint256 nonce = 0;
    address private mainContractAddress = address(this);
    string internal yin = 'yin';
    string internal yang = 'yang';
    string internal bang = 'bang';
    string internal zero = 'zero';
    string internal odd = 'odd';
    string internal even = 'even';
    uint256 private yinMultiplier = 21888;
    uint256 private yangMultiplier = 21888;
    uint256 private bangMultiplier = 98500;
    uint256 private zeroMultiplier = 985000;
    uint256 private oddMultiplier = 19700;
    uint256 private evenMultiplier = 19700;
    uint256 public totalFrozenTopia;
        
    uint256 public confirmedDividendForFreeze;
    uint256 public confirmedDividendForLeaderBoard;
    uint256 public dividendPaidAllTime;
    uint256 public dividendThreshold = 500000 * (10**tronDecimals);

    mapping(address => uint256) public frozenTopiaReleaseAmount;
    mapping(address => uint256) public frozenTopiaReleaseTime;
    mapping(address => uint256) public mainDividendPaid;
    mapping(address => uint256) public leaderboardDividendPaid;

    /* Records for the fronzen accounts */
    mapping (address => bool) public frozenAccount;
    // This creates an array with all balances
    mapping (address => uint256) public balanceOf;

    //minttoken tracker
    //mapping (address => uint256) public mintTracker;

    //frozen topia tracker
    mapping (address => uint256) public frozenTopia;

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
    //  constructor (
    //    // uint256 initialSupply,
    //     string memory tokenName,
    //     string memory tokenSymbol
    // ) public {
    //     //totalSupply = initialSupply.mul(10**decimals);          // Update total supply with the decimal amount
    //     //balanceOf[mainContractAddress] = totalSupply;           //100% will assign in contract
    //    // balanceOf[mainContractAddress] = 500000;                // dividend pool initial value
    //     name = tokenName;                                       // Set the name for display purposes
    //     symbol = tokenSymbol;                                   // Set the symbol for display purposes
        
    //     emit Transfer(address(0), mainContractAddress, totalSupply);
    // }
    
    event Roll(address indexed user, uint _startNumber, uint _endNumber, uint _winningNumber, uint256 _value, bool result,uint256 timestamp);
    event KingTopian(address indexed user, uint256 _prize, uint256 _trxplayed, uint256 timestamp);
    event UnluckyBunch(address indexed user, uint256 _loose, uint256 _trxplayed, uint256 timestamp);
    event HighRollers(address indexed user, uint _startNumber, uint _endNumber, uint _winningNumber, uint256 _value, uint256 _winamount, bool result,uint256 timestamp);
    event RareWins(address indexed user, uint _startNumber, uint _endNumber, uint _winningNumber, uint256 _value, uint256 _winamount, bool result,uint256 timestamp);
    event SideBetRolls(address indexed user, uint _winningNumber, uint256 _betValue, uint256 winAmount, string sideBet, bool result,uint256 timestamp);
    //event SideBetWins(address indexed user, uint _winningNumber, uint256 _betValue, uint256 winAmount, string sideBet, bool result,uint256 timestamp);
    event MintTracker(address indexed user,uint token,uint256 timestamp);
    event dividendPaid(uint256 currentTRXBalance, uint256 totalDividendPaid);
    /*generate random hash seed */
    function getSeed() public view returns(bytes32){
        return keccak256(now);
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
    
    uint256 public TotalBetsMade =0;
    uint256 public TotalWinAmount =0;
    uint256 public minimumTokenRequirement = 100 * (10**decimals);     //User must have at least 100 Tokens to be eligible to receive winnings
    uint256 public poolMinimumRequirement = 1000000 * (10**tronDecimals);  //1 Million

    
     
    bytes internal _yin = bytes(yin);
    bytes internal _yang = bytes(yang);
    bytes internal _bang = bytes(bang);
    bytes internal _zero = bytes(zero);
    bytes internal _odd = bytes(odd);
    bytes internal _even = bytes(even);
    uint256 sideBetsWin ;
    uint256 firstNumber;
    uint256 lastNumber;               
    uint _refBonus;
    uint256 multiplier;
    uint256 winamount;
    uint256 winamount2;
    uint256 _winningNumber;
    uint256 range;
    uint256 mToken;
    bool _sideBetStatus = false;
    uint256 totalTokenOfContract;
    //--- Data storage variables -----------------------//
    
    
   // mapping(bytes32=>uint256) TotalBetsMade;     //Mapping holds purchase volume for each community
    
    
    //addMultiplier to store multiplier array data in contract
    function addMultiplier (uint256[] memory data) public onlyOwner returns(string){
        multipliersData = data;
        return "Multiplyer Added";
    }

   
    //distribute dividend to players
    function distributeMainDividend() public onlyOwner returns(string){
        if(address(this).balance > (dividendThreshold + dividendPaidAllTime) ){
            uint256 dividendAmount = address(this).balance - ( dividendThreshold + dividendPaidAllTime );
            confirmedDividendForFreeze = confirmedDividendForFreeze.add(dividendAmount * 990 / 1000); //99% to dividend pool
            confirmedDividendForLeaderBoard = confirmedDividendForLeaderBoard.add(dividendAmount  / 100); //1% to leaderboard (king topian and unlucky bunch)

            dividendPaidAllTime = dividendPaidAllTime.add(dividendAmount);

            emit dividendPaid(address(this).balance, dividendAmount);
        }
        else{
            revert(); //we dont want to succeed the call if there is no dividends available to pay
        }
        
    }

    function distributeLuckyWinners(address[] luckyWinners) public onlyOwner {

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

        //updating the confirmedDividendForLeaderBoard variable
        confirmedDividendForLeaderBoard = confirmedDividendForLeaderBoard / 2;

    }

    function distributeUnluckyLosers(address[] unluckyLosers) public onlyOwner {

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
        confirmedDividendForLeaderBoard = confirmedDividendForLeaderBoard / 2;
    
    }

    function displayAvailableDividendALL() public view returns (uint256){
        if(address(this).balance > (dividendThreshold + dividendPaidAllTime) ){
            return address(this).balance - (dividendThreshold + dividendPaidAllTime);
        }
        else{
            return 0;
        }
    }

    function displayAvailabletoWithdrawTRX() public view returns(uint256[]){

        //this will give sum of mainDividendAvailable and leaderboardDividendAvailable 
        uint256 mainDividendAvailable;
        uint256 leaderboardDividendAvailable;
        
        //calculating  mainDividendAvailable
        //first calculating user share percentage = user freeze tokens * 100 / total frozen tokens
        uint256 sharePercentage = frozenTopia[msg.sender] * 100 * tronDecimals / totalFrozenTopia;
        //now calculating final trx amount from ( available dividend pool * share percentage / 100) - already paid main dividend
        mainDividendAvailable = (confirmedDividendForFreeze * sharePercentage / 100 / tronDecimals).sub(mainDividendPaid[msg.sender]);
        
        //creating array, which will have main and leaderboard dividends
        uint256[] dividendArray;

        dividendArray.push(mainDividendAvailable);
        dividendArray.push(leaderboardDividendPaid[msg.sender]);

        return dividendArray;

    }

    function displayAvailabletoWithdrawTOPIA() public view returns(uint256){
        if(frozenTopiaReleaseTime[msg.sender] < now){
            return frozenTopiaReleaseAmount[msg.sender];
        }
        else{
            return 0;
        }
    }

    function withdrawDividendTRXandTopia() public {
        uint256[] memory availableDividendTRX = displayAvailabletoWithdrawTRX();
        uint256 availableMainDividend = availableDividendTRX[0];
        uint256 availableLeaderboardDividend = availableDividendTRX[1];
        uint256 availableTopia = displayAvailabletoWithdrawTOPIA();

        //processing unfreeze topia
        if(availableTopia > 0){
            frozenTopiaReleaseAmount[msg.sender] = 0;
            _transfer(address(this), msg.sender, availableTopia);
        }

        //processing main dividend
        if(availableMainDividend > 0){
            mainDividendPaid[msg.sender] = mainDividendPaid[msg.sender].add(availableMainDividend);
        }

        //processing leaderboard dividend
        if(availableLeaderboardDividend > 0){
            leaderboardDividendPaid[msg.sender] = 0;
        }

        //transferring TRX to caller if available
        msg.sender.transfer(availableMainDividend + availableLeaderboardDividend);

    }

    function changeDividendThreshold(uint256 newThresholdAmount) public onlyOwner {

        require(newThresholdAmount != 0, 'Amount can not be zero');
        dividendThreshold = newThresholdAmount;

    }

    function freezeTopia(uint256 _value) public returns(bool){

        //to freeze topia, we just take topia from his account and transfer to contract address, 
        //and track that with frozenTopia mapping variable
        _transfer(msg.sender, address(this), _value);

        frozenTopia[msg.sender] = frozenTopia[msg.sender].add(_value);
        totalFrozenTopia = totalFrozenTopia.add(_value);

        return true;
    }
  
    function unfreezeTopia(uint256 _value) public returns(bool){

        require(frozenTopia[msg.sender] >= (_value + frozenTopiaReleaseAmount[msg.sender]), 'Insufficient Tokens');

        frozenTopiaReleaseAmount[msg.sender] = frozenTopiaReleaseAmount[msg.sender].add(_value);
        frozenTopiaReleaseTime[msg.sender] = now + 86400;

        frozenTopia[msg.sender] = frozenTopia[msg.sender].sub(_value);
        totalFrozenTopia = totalFrozenTopia.sub(_value);
        return true;

    }
    
    //function to roll dice and win or loose game
    function roll(uint _startNumber,uint _endNumber,uint _amount, bytes32 _seed, address _referrer, string _sideBet, uint256 _sideBetvalue) payable public returns(bool, uint256, bool) {
            //require(_startNumber >0, 'Invalid _startNumber');
            //require(_endNumber >0, 'Invalid _endNumber');
            require(_amount >0, 'Invalid _amount');
            require(_seed !=bytes32(0), 'Invalid _seed');

            _winningNumber = random(_seed);
            range = _endNumber-_startNumber;
            bytes memory _sideBetM = bytes(_sideBet);
            
            _sideBetStatus = false;
            TotalBetsMade++;
            
            if(_amount>=833){
               // uint256 stage = address(this).balance.div(1000000000000);
                //uint256 stage = address(this).balance.div(10000000000);
                //uint256 stage = mintTracker[mainContractAddress].div(1000000);
                totalTokenOfContract = balanceOf[mainContractAddress].div(10000000000000000);
                //uint256 stage = balanceOf[mainContractAddress].div(10000000000000000);
                uint256 token;
                uint256 stage;
                if(totalTokenOfContract<1000000){
                    stage =833;
                    token = _amount.div(833);
                }else{
                    stage = totalTokenOfContract.div(1000000);
                    stage = stage.mul(20);
                    stage = stage.add(1000);
                    stage = stage.sub(20);
                    token = _amount.div(1000);
                }
               
                // if(stage==0){
                //     //stage = stage.mul(20);
                //     //stage = stage.add(1000);
                //     //stage = stage.sub(20);
                //     token = _amount.div(833);
                // }else{
                //     stage = stage.mul(20);
                //     stage = stage.add(1000);
                //     stage = stage.sub(20);
                //     token = _amount.div(1000);
                // }
                                
                if(_amount>=stage){
                    balanceOf[msg.sender] = balanceOf[msg.sender].add(token);
                    totalSupply = totalSupply.add(token);
                    mToken = 66666666;
                    token = token*mToken;
                    balanceOf[mainContractAddress] = balanceOf[mainContractAddress].add(token);
                    totalSupply = totalSupply.add(token);
                    emit MintTracker(msg.sender,token,now);
                }
                    
            }

             //sidebets code 
                if(keccak256(_sideBetM) == keccak256(_yin)){
                     firstNumber = _winningNumber.div(10);
                     lastNumber = firstNumber.mul(10);
                    
                    lastNumber = _winningNumber.sub(lastNumber);
                    if(firstNumber>lastNumber){
                        _sideBetStatus = true;
                         sideBetsWin = _sideBetvalue.mul(yinMultiplier);
                         sideBetsWin = sideBetsWin.mul(100);
                         TotalWinAmount = TotalWinAmount.add(sideBetsWin);
                        //_transfer(mainContractAddress, msg.sender, sideBetsWin);
                        msg.sender.transfer(sideBetsWin);
                    }
                    emit SideBetRolls(msg.sender, _winningNumber, _sideBetvalue,  sideBetsWin, _sideBet, _sideBetStatus, now);                    
                }
                if(keccak256(_sideBetM) == keccak256(_yang)){
                     firstNumber = _winningNumber.div(10);
                     lastNumber = firstNumber.mul(10);
                    lastNumber = _winningNumber.sub(lastNumber);
                    if(firstNumber<lastNumber){
                        _sideBetStatus = true; 
                        sideBetsWin = _sideBetvalue.mul(yangMultiplier);
                        sideBetsWin = sideBetsWin.mul(100);
                        TotalWinAmount = TotalWinAmount.add(sideBetsWin);
                        msg.sender.transfer(sideBetsWin);
                        
                    }
                    emit SideBetRolls(msg.sender, _winningNumber, _sideBetvalue,  sideBetsWin, _sideBet, _sideBetStatus, now);                    
                }
                if(keccak256(_sideBetM) == keccak256(_bang)){
                     if (_winningNumber == 0 || _winningNumber == 11 || _winningNumber == 22 || _winningNumber == 33 || _winningNumber == 44 || _winningNumber == 55 || _winningNumber == 66 || _winningNumber == 77 || _winningNumber == 88 || _winningNumber == 99) {
                       _sideBetStatus = true; 
                        sideBetsWin = _sideBetvalue.mul(bangMultiplier);
                        sideBetsWin = sideBetsWin.mul(100);
                        TotalWinAmount = TotalWinAmount.add(sideBetsWin);
                        msg.sender.transfer(sideBetsWin);
                        
                    } 
                    emit SideBetRolls(msg.sender, _winningNumber, _sideBetvalue,  sideBetsWin, _sideBet, _sideBetStatus, now);                    
                }
                if(keccak256(_sideBetM) == keccak256(_zero)){
                    if (_winningNumber == 0  ) {
                       _sideBetStatus = true; 
                        sideBetsWin = _sideBetvalue.mul(zeroMultiplier);
                        sideBetsWin = sideBetsWin.mul(100);
                        TotalWinAmount = TotalWinAmount.add(sideBetsWin);
                        msg.sender.transfer(sideBetsWin);
                    }
                    emit SideBetRolls(msg.sender, _winningNumber, _sideBetvalue,  sideBetsWin, _sideBet, _sideBetStatus, now);                    
                }
                if(keccak256(_sideBetM) == keccak256(_odd)){
                    if (_winningNumber % 2 != 0  ) {
                       _sideBetStatus = true; 
                        sideBetsWin = _sideBetvalue.mul(oddMultiplier);
                        sideBetsWin = sideBetsWin.mul(100);
                        TotalWinAmount = TotalWinAmount.add(sideBetsWin);
                        msg.sender.transfer(sideBetsWin);
                    }
                    emit SideBetRolls(msg.sender, _winningNumber, _sideBetvalue,  sideBetsWin, _sideBet, _sideBetStatus, now);                    
                }
                if(keccak256(_sideBetM) == keccak256(_even)){
                    if (_winningNumber % 2 == 0  ) {
                        _sideBetStatus = true;
                         sideBetsWin = _sideBetvalue.mul(evenMultiplier);
                         sideBetsWin = sideBetsWin.mul(100);
                         TotalWinAmount = TotalWinAmount.add(sideBetsWin);
                         msg.sender.transfer(sideBetsWin);
                    }    
                    emit SideBetRolls(msg.sender, _winningNumber, _sideBetvalue,  sideBetsWin, _sideBet, true, now);                                    
                }


            if(_winningNumber>=_startNumber && _winningNumber<=_endNumber){
                if(range==0){
                    multiplier = multipliersData[range];
                }else{
                    multiplier = multipliersData[range--];
                }

                winamount = _amount.mul(multiplier);
                TotalWinAmount = TotalWinAmount.add(winamount);
                winamount2 = winamount.mul(100);
                
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

               
                //balanceOf[msg.sender] = balanceOf[msg.sender].add(winamount);
                //_transfer(mainContractAddress, msg.sender, winamount);
              
                msg.sender.transfer(winamount2);
                emit Transfer(mainContractAddress, msg.sender,winamount);
                emit Roll(msg.sender,_startNumber, _endNumber, _winningNumber, _amount, true, now);
                emit KingTopian(msg.sender, winamount2, _amount, now);

                if(_amount>10000){
                    emit HighRollers(msg.sender,_startNumber, _endNumber, _winningNumber, _amount, winamount2, true, now);
                }
                if(range<5){
                    emit RareWins(msg.sender,_startNumber, _endNumber, _winningNumber, _amount, winamount2, true, now);
                }

                return (true,_winningNumber,_sideBetStatus);
            }else{
                 
                 //balanceOf[mainContractAddress] = balanceOf[mainContractAddress].add(_amount);
                if(_referrer != address(0x0) && referrers[msg.sender] == address(0x0)){ 
                    //adding referral details in both the mappings
                    referrers[msg.sender]=_referrer;
                }
                 
                 emit UnluckyBunch(msg.sender, _amount, _amount, now);
                 emit Roll(msg.sender, _startNumber, _endNumber, _winningNumber, _amount, false, now);
                 return (false,_winningNumber,_sideBetStatus);
            }
    }
    //function to generate random number
    function random(bytes32 seed) internal returns (uint) {
            uint randomnumber = uint(keccak256(abi.encodePacked(now, msg.sender, nonce, seed))) % 99;
            randomnumber = randomnumber;
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