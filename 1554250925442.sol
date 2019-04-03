pragma solidity 0.4.25; /*


  _______ _____   ____  _   _ _              _           _____                          _       
 |__   __|  __ \ / __ \| \ | | |            (_)         |  __ \                        | |      
    | |  | |__) | |  | |  \| | |_ ___  _ __  _  __ _    | |__) | __ ___  ___  ___ _ __ | |_ ___ 
    | |  |  _  /| |  | | . ` | __/ _ \| '_ \| |/ _` |   |  ___/ '__/ _ \/ __|/ _ \ '_ \| __/ __|
    | |  | | \ \| |__| | |\  | || (_) | |_) | | (_| |   | |   | | |  __/\__ \  __/ | | | |_\__ \
    |_|  |_|  \_\\____/|_| \_|\__\___/| .__/|_|\__,_|   |_|   |_|  \___||___/\___|_| |_|\__|___/
                                      | |                                                       
                                      |_|                                                       


    ██╗   ██╗██╗  ████████╗██╗███╗   ███╗ █████╗ ████████╗███████╗    ██████╗ ██╗ ██████╗███████╗
    ██║   ██║██║  ╚══██╔══╝██║████╗ ████║██╔══██╗╚══██╔══╝██╔════╝    ██╔══██╗██║██╔════╝██╔════╝
    ██║   ██║██║     ██║   ██║██╔████╔██║███████║   ██║   █████╗      ██║  ██║██║██║     █████╗  
    ██║   ██║██║     ██║   ██║██║╚██╔╝██║██╔══██║   ██║   ██╔══╝      ██║  ██║██║██║     ██╔══╝  
    ╚██████╔╝███████╗██║   ██║██║ ╚═╝ ██║██║  ██║   ██║   ███████╗    ██████╔╝██║╚██████╗███████╗
    ╚═════╝ ╚══════╝╚═╝   ╚═╝╚═╝     ╚═╝╚═╝  ╚═╝   ╚═╝   ╚══════╝    ╚═════╝ ╚═╝ ╚═════╝╚══════╝
                                                                                                


----------------------------------------------------------------------------------------------------

=== MAIN FEATURES ===
    => Higher degree of control by owner - safeguard functionality
    => SafeMath implementation 
    => Random Number generation using: timestamp, user address, nonce, seed, and previous block-hash
    => Dividend payout
    => Sidebet Jackpot
    => Topia Freeze Tiers
    => Referral Tiers

=== Independant Audit of the code ===
    => https://hacken.io
    => Multiple Freelancers Auditors
    => Community Audit by Bug Bounty program


------------------------------------------------------------------------------------------------------
 Copyright (c) 2019 onwards TRONtopia Inc. ( https://trontopia.co )
 Contract designed by EtherAuthority  ( https://EtherAuthority.io )
------------------------------------------------------------------------------------------------------
*/ 


//*******************************************************************//
//------------------------ SafeMath Library -------------------------//
//*******************************************************************//
library SafeMath {

    function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
        if (a == 0) {
            return 0;
        }

        c = a * b;
        require(c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        return a - b;
    }
    
    function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
        c = a + b;
        require(c >= a);
        return c;
    }
}

//*******************************************************************//
//------------------ Contract to Manage Ownership -------------------//
//*******************************************************************//
    

contract owned {
    address public owner;
    address public newOwner;

    event OwnershipTransferred(address indexed _from, address indexed _to);

    constructor() public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address _newOwner) public onlyOwner {
        newOwner = _newOwner;
    }

    //the reason for this flow is to protect owners from sending ownership to unintended address due to human error
    function acceptOwnership() public {
        require(msg.sender == newOwner);
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
        newOwner = address(0);
    }
}

//**************************************************************************//
//---------------------  TRONTOPIA CONTRACT INTERFACE  ---------------------//
//**************************************************************************//

interface TRONtopiaInterface {
    function transfer(address recipient, uint amount) external returns(bool);
    function mintToken(address _user, uint256 _tronAmount)  external returns(bool);
    function referrers(address user) external returns(address);
    function updateReferrer(address _user, address _referrer) external returns(bool);
    function payReferrerBonusOnly(address _user, uint256 _refBonus, uint256 _trxAmount ) external returns(bool);
    function payReferrerBonusAndAddReferrer(address _user, address _referrer, uint256 _trxAmount, uint256 _refBonus) external returns(bool);
} 
    
//**************************************************************************//
//---------------------  DICE GAME MAIN CODE STARTS HERE ---------------------//
//**************************************************************************//

contract TRONtopia_ultimate_dice is owned{
    /* Public variables of the contract */
    using SafeMath for uint256;
    uint256[] public multipliersData;
    uint256 private nonce = 0;
    address private mainContractAddress = address(this);
    address public topiaTokenContractAddress;
    uint256 public constant decimals = 8;
    uint256 public totalDepositedTRX;

    uint256 private constant  _yin = 1;
    uint256 private constant _yang = 2;
    uint256 private constant _bang = 3;
    uint256 private constant _zero = 4;
    uint256 private constant  _odd = 5;
    uint256 private constant _even = 6; 

    uint256 private yinMultiplier = 21111;
    uint256 private yangMultiplier = 21111;
    uint256 private bangMultiplier = 95000;
    uint256 private zeroMultiplier = 950000;
    uint256 private oddMultiplier = 19000;
    uint256 private evenMultiplier = 19000;

    uint256 private constant tronDecimals=6;
    uint256 public constant minimumTokenRequirement = 10000000000;      //User must have at least 100 Tokens to be eligible to receive winnings
    uint256 public constant poolMinimumRequirement = 1000000000000;     //1 Million
               
    uint256 private range;
    uint256 public maxBetAmount = 500000;
    uint256 public maxWinDivisibleAmount = 50;

    //side bet jackpot variables
    uint256 public sideBetJackpotAmountMultiplier = 1000;   // 1000 is multiplier to calculate trx for sidebet jackpot
    uint256 public sideBetJackpotMaxOdd = 1000000;          // 1 Million is highest odd of sidebet jackpot
    uint256 public sideBetJackpotFixNumber = 1000;          // so the odd to get this number would be 1:1000000
    uint256 public maxSidebetJackpotAmount = 250000000000;   // 250K trx is the maximum sidebet jackpot amount

    
    event Roll(address indexed user, uint256 _startNumber, uint256 _endNumber, uint256 _winningNumber, uint256 indexed _value, bool indexed result,uint256 timestamp);
    event KingTopian(address indexed user, uint256 _prize, uint256 _trxplayed, uint256 timestamp);
    event UnluckyBunch(address indexed user, uint256 _loose, uint256 _trxplayed, uint256 timestamp);
    event HighRollers(address indexed user, uint256 _startNumber, uint256 _endNumber, uint256 _winningNumber, uint256 _value, uint256 _winamount, bool result,uint256 timestamp);
    event RareWins(address indexed user, uint256 _startNumber, uint256 _endNumber, uint256 _winningNumber, uint256 _value, uint256 _winamount, bool result,uint256 timestamp);
    event SideBetRolls(address indexed user, uint256 _winningNumber, uint256 _betValue, uint256 winAmount, uint256 sideBet, bool result,uint256 timestamp);
    event SideBetJackpot(address indexed winner, uint256 lukyNumber );

    /**
        Fallback function. It just accepts incoming TRX
    */
    function () payable external {}

    /**
        generate random hash seed 
    */
    function getSeed() public view returns(bytes memory){
        return abi.encodePacked(now);
    }

    /**addMultiplier to store multiplier array data in contract
    // Following array must be put as input

        [985000,492500,328333,246250,197000,164166,140714,123125,109444,98500,89545,82083,75769,70357,65666,61562,57941,54722,51842,49250,46904,44772,42826,41041,39400,37884,36481,35178,33965,32833,31774,30781,29848,28970,28142,27361,26621,25921,25256,24625,24024,23452,22906,22386,21888,21413,20957,20520,20102,19700,19313,18942,18584,18240,17909,17589,17280,16982,16694,16416,16147,15887,15634,15390,15153,14924,14701,14485,14275,14071,13873,13680,13493,13310,13133,12960,12792,12628,12468,12312,12160,12012,11867,11726,11588,11453,11321,11193,11067,10944,10824,10706,10591,10478,10368,10260,10155]

    */
    function addMultiplier (uint256[] memory data) public onlyOwner returns(string){
        multipliersData = data;
        return "Multiplier Added";
    }


    /**
    * function to roll dice and win or loose game
    * SafeMath is NOT used, as underflow/overflow was impossible. And it would save lot of energy cost!
    * 
    * uint256[] rollIntegerVariables array contains:
    * rollIntegerVariables[0] = _startNumber;
    * rollIntegerVariables[1] = _endNumber;
    * rollIntegerVariables[2] = _amount;
    * rollIntegerVariables[3] = _sideBetvalue;
    * rollIntegerVariables[4] = _sideBetName;
        yin = 1
        yang = 2
        bang = 3
        zero = 4
        odd = 5
        even = 6
        
    */
    function roll(uint256[] rollIntegerVariables, bytes32 _seedPlayer,  address _referrer) payable public {

        //checking conditions
        require(msg.value == (rollIntegerVariables[2]+rollIntegerVariables[3]) * 1e6 && rollIntegerVariables[2] >= 10, 'Invalid _amount');
        require(rollIntegerVariables[2] <= maxBetAmount, 'Bet amount too large');
        require(rollIntegerVariables[1] >= rollIntegerVariables[0] && rollIntegerVariables[1] < 100, 'End number must be greater than or equal to start number');
        require(msg.sender == tx.origin, 'Caller must not be Contract Address'); //no contract callers allowed
        if(rollIntegerVariables[3] > 0) { require(rollIntegerVariables[3] >= 25, 'If sidebet is placed, then it can not be les than 25 trx'); }

        uint256 _winningNumber = random(_seedPlayer);
        uint256 winamount;
        uint256 mainBetNetWin;
        address _referrerInMapping = TRONtopiaInterface(topiaTokenContractAddress).referrers(msg.sender);

        
        // mint tokens depending on how much TRX is received
        TRONtopiaInterface(topiaTokenContractAddress).mintToken(msg.sender, msg.value);

        // finding sidebets  
        (bool _sideBetStatus, uint256 sideBetsWin, uint256 sideBetNetWin) = findingSideBet(_winningNumber, rollIntegerVariables[4], rollIntegerVariables[3]);
        

        // finding main bet winning code START ------------------------------------------------->>
        if(_winningNumber>=rollIntegerVariables[0] && _winningNumber<=rollIntegerVariables[1]){
            range = rollIntegerVariables[1] - rollIntegerVariables[0];

            winamount = rollIntegerVariables[2] * multipliersData[range] * 100;  
            mainBetNetWin = winamount - (rollIntegerVariables[2] * 1e6);
        }
        // finding main bet winning code ENDS ------------------------------------------------->>


        // we want to restrict that winning of TRX can not be higher than TRX balance of contract / 50
        // totalWinning TRX (which is: sideBetsWin + winamount) - input TRX amount <= contract balance / 50
        require(sideBetNetWin + mainBetNetWin <= address(this).balance / maxWinDivisibleAmount, 'Max bet win reached');

        if(rollIntegerVariables[3] > 0){

            //this is for sidebet jackpot was won by player
            randomForSidebetJackpot(rollIntegerVariables[3]);
            
            emit SideBetRolls(msg.sender, _winningNumber, rollIntegerVariables[3],  sideBetsWin, rollIntegerVariables[4], _sideBetStatus, now); 
        }

        if(_winningNumber>=rollIntegerVariables[0] && _winningNumber<=rollIntegerVariables[1]){
                                    
            emit Roll(msg.sender,rollIntegerVariables[0], rollIntegerVariables[1], _winningNumber, rollIntegerVariables[2], true, now);
            emit KingTopian(msg.sender, winamount, rollIntegerVariables[2], now);

            if(rollIntegerVariables[2]>10000){
                emit HighRollers(msg.sender,rollIntegerVariables[0], rollIntegerVariables[1], _winningNumber, rollIntegerVariables[2], winamount, true, now);
            }
            if(range<5){
                emit RareWins(msg.sender,rollIntegerVariables[0], rollIntegerVariables[1], _winningNumber, rollIntegerVariables[2], winamount, true, now);
            }
        }

        // following condition will run if there were no winning for the mainbet
        else{
            if(_referrer != address(0) && _referrerInMapping == address(0)){
                //adding referral details in referrer mapping in topiaContract
                TRONtopiaInterface(topiaTokenContractAddress).updateReferrer(msg.sender, _referrer);
            }
            emit UnluckyBunch(msg.sender, rollIntegerVariables[2], rollIntegerVariables[2], now);
            emit Roll(msg.sender, rollIntegerVariables[0], rollIntegerVariables[1], _winningNumber, rollIntegerVariables[2], false, now);
        }

        //following condition is when anyone of sidebet or mainbet won
        uint256 _refBonus = sideBetNetWin + mainBetNetWin;
        if( _refBonus > 0){

            
            /** Processing referral system fund distribution **/
            // [✓] 0.2% trx to referral if any.

            // Case 1: player have used referral links
            if(_referrer != address(0) && _referrerInMapping != address(0)){
                TRONtopiaInterface(topiaTokenContractAddress).payReferrerBonusOnly(msg.sender, _refBonus, msg.value );
            }
            
            // Case 2: player has existing referrer/up-line/direct sponsor, but he did not use any referrer link or sent trx directly to smart contract
            // In this case, trx will be sent to existing referrer
            else if(_referrer == address(0) && _referrerInMapping != address(0)){
                TRONtopiaInterface(topiaTokenContractAddress).payReferrerBonusOnly(msg.sender, _refBonus, msg.value );
            }
            
            // Case 3: depositor does not have any existing direct referrer, but used referral link
            // In this case, referral bonus will be paid to address in the referral link
            else if(_referrer != address(0) && _referrerInMapping == address(0)){
                TRONtopiaInterface(topiaTokenContractAddress).payReferrerBonusAndAddReferrer(msg.sender, _referrer, msg.value, _refBonus);
            }
           
            msg.sender.transfer(winamount + sideBetsWin);
        }

    }

    /**
        This function allows to get sidebet win status and its data
    */
    function findingSideBet(uint256 _winningNumber, uint256 _sideBetName, uint256 _sideBetvalue) internal view returns(bool, uint256, uint256){
        
        if(_sideBetName != 0){

            bool _sideBetStatus;
            uint256 sideBetsWin;
            uint256 sideBetNetWin;
            uint256 firstNumber = _winningNumber / 10;
            uint256 lastNumber = _winningNumber - (firstNumber * 10);
            
            if( _sideBetName == _yin ){
                
                if(firstNumber>lastNumber){
                    _sideBetStatus = true;
                    sideBetsWin = _sideBetvalue * yinMultiplier * 100;
                    sideBetNetWin = sideBetsWin - (_sideBetvalue * 1e6);
                }        
            }
            else if( _sideBetName == _yang ){
                
                if(firstNumber<lastNumber){
                    _sideBetStatus = true; 
                    sideBetsWin = _sideBetvalue * yangMultiplier * 100;
                    sideBetNetWin = sideBetsWin - (_sideBetvalue * 1e6);
                }                   
            }
            else if( _sideBetName == _bang ){
                if (_winningNumber == 0 || _winningNumber == 11 || _winningNumber == 22 || _winningNumber == 33 || _winningNumber == 44 || _winningNumber == 55 || _winningNumber == 66 || _winningNumber == 77 || _winningNumber == 88 || _winningNumber == 99) {
                    _sideBetStatus = true; 
                    sideBetsWin = _sideBetvalue * bangMultiplier * 100;
                    sideBetNetWin = sideBetsWin - (_sideBetvalue * 1e6);
                }                   
            }
            else if( _sideBetName == _zero ){
                if (_winningNumber == 0  ) {
                    _sideBetStatus = true; 
                    sideBetsWin = _sideBetvalue * zeroMultiplier * 100;
                    sideBetNetWin = sideBetsWin - (_sideBetvalue * 1e6);
                }                
            }
            else if( _sideBetName == _odd ){
                if (_winningNumber % 2 != 0  ) {
                    _sideBetStatus = true; 
                    sideBetsWin = _sideBetvalue * oddMultiplier * 100;
                    sideBetNetWin = sideBetsWin - (_sideBetvalue * 1e6);
                }
            }
            else if( _sideBetName == _even ){
                if (_winningNumber % 2 == 0  ) {
                    _sideBetStatus = true;
                    sideBetsWin = _sideBetvalue * evenMultiplier * 100; 
                    sideBetNetWin = sideBetsWin - (_sideBetvalue * 1e6);  
                }                                           
            }
            
            return (_sideBetStatus, sideBetsWin, sideBetNetWin);
        }
    }


    /**
        function to generate random number for roll function
    */
    function random(bytes32 seed) internal returns (uint) {
            nonce++;
            return uint(keccak256(abi.encodePacked(now, msg.sender, nonce, seed, blockhash(block.number - 1)))) % 99;
    }

    /**
        function to generate random number for side bet jackpot function.
        It returns true if user won the sidebet. otherwise false.
    */
    function randomForSidebetJackpot(uint256 sideBetAmount) internal {
      
        //this function produces random number from 0 - 1,000,000 
        uint randomNumber = uint(keccak256(abi.encodePacked(now, msg.sender, nonce, blockhash(block.number - 1)))) % sideBetJackpotMaxOdd;
        
        //we will be checking if the random number is same as pre-defined fix number, currently 1000.
        //so there would be probability to get that one number is 1:1000000
        //if user won the jackpot, then they will get that using below condition
        if(randomNumber == sideBetJackpotFixNumber){

            //calculating jackpot amount
            uint256 sideBetJackpotAmount = sideBetAmount * 1000000 * sideBetJackpotAmountMultiplier;
            
            //we want the max cap of sideback jackpot to be only 250K trx (changeable by owner)
            if(sideBetJackpotAmount > maxSidebetJackpotAmount){
                sideBetJackpotAmount = maxSidebetJackpotAmount;
            }
            
            msg.sender.transfer(sideBetJackpotAmount);
            emit SideBetJackpot(msg.sender, randomNumber );
        }
    }

    /**
        This functions allows owner to update the sidebet jeckpot variables
    */
    function updateSideBetJackpot (uint256 _sideBetJackpotAmountMultiplier, uint256 _maxSidebetJackpotAmount, uint256 _sideBetJackpotMaxOdd, uint256 _sideBetJackpotFixNumber) public onlyOwner returns(string){
        
        sideBetJackpotAmountMultiplier = _sideBetJackpotAmountMultiplier; 
        maxSidebetJackpotAmount = _maxSidebetJackpotAmount;
        sideBetJackpotMaxOdd = _sideBetJackpotMaxOdd;    
        sideBetJackpotFixNumber = _sideBetJackpotFixNumber;

        return("Sidebet Jackpot variables updated successfully");
    }


    /** 
        This function just gives total balance of contract
    */
    function totalTRXbalanceContract() public view returns(uint256){
        return address(this).balance;
    }

    /**
        function to deposit TRX into smart contract. It will update dividend threshold and totalDepositedTRX tracker 
        function you dont want these things to update, then just send TRX to contract address
    */
    function depositTRX() payable public onlyOwner returns(string){
        
        //updating totalDepositedTRX tracker 
        totalDepositedTRX += msg.value;

        //changing dividend threshold according to how much TRX deposited by owner
        dividendThreshold = dividendThreshold.add(msg.value);
        
        return "Transaction successful";
    }

    /**
        This function lets owner to withdraw TRX as much he deposited.
        Thus there is NO "exit scam" possibility, as there is no other way to take TRX out of this contract
    */
    function manualWithdrawTRX(uint256 amount) public onlyOwner returns(string){
        
        //checking conditions
        require(totalDepositedTRX >= amount, 'Invalid amount');

        //changing dividend threshold according to how much TRX deposited by owner
        dividendThreshold = dividendThreshold.sub(amount);

        //updating tracker
        totalDepositedTRX -= amount;

        //transferring the TRX to owner
        owner.transfer(amount);

        return "Transaction successful";
    }
    
    /**
        Just in rare case, owner wants to transfer Tokens from contract to owner address
    */
    function manualWithdrawTokens(uint256 tokenAmount) public onlyOwner returns(string){
        
        // no need for overflow checking as that will be done in transfer function
        TRONtopiaInterface(topiaTokenContractAddress).transfer(msg.sender, tokenAmount);
        
        return "Transaction successful";
    }

    /**
        Function allows owner to upate the Topia contract address
    */
    function updateTopiaTokenContractAddress(address _newAddress) public onlyOwner returns(string){
        
        require(_newAddress != address(0), 'Invalid Address');
        topiaTokenContractAddress = _newAddress;

        return "Topia Token Contract Address Updated";
    }

    /**
        Function allows owner to update the sidebet multiplier variables
    */
    function updateSidebetMultipliers(uint256 yinMultiplier_, uint256 yangMultiplier_, uint256 bangMultiplier_, uint256 zeroMultiplier_, uint256 oddMultiplier_, uint256 evenMultiplier_  ) public onlyOwner returns(string){
        
        yinMultiplier = yinMultiplier_;
        yangMultiplier = yangMultiplier_;
        bangMultiplier = bangMultiplier_;
        zeroMultiplier = zeroMultiplier_;
        oddMultiplier = oddMultiplier_;
        evenMultiplier = evenMultiplier_;

        return("side bet multipliers updated successfully");
    }

    /**
        Function to change max bet amount and max bet divisible amount.
    */
    function updateMaxBetMaxWin(uint256 maxBetAmount_, uint256 maxWinDivisibleAmount_  ) public onlyOwner returns(string){
        
        maxBetAmount = maxBetAmount_;
        maxWinDivisibleAmount = maxWinDivisibleAmount_;

        return("Max bet and max win updated successfully");
    }


    

    //-------------------------------------------------//
    //---------------- DIVIDEND SECTION ---------------//
    //-------------------------------------------------//

    uint256 public dividendThreshold;   //dividend threshold
    uint256 public dividendPaidAllTime;

    /**
    *   Function to view available dividend amount
    */
    function displayAvailableDividend() public view returns (bool, uint256){

        if(address(this).balance >= (dividendThreshold + dividendPaidAllTime) ){
            return (true, address(this).balance - (dividendThreshold + dividendPaidAllTime));
        }
        else{
            return (false, (dividendThreshold + dividendPaidAllTime) - address(this).balance );
        }
    }


    /**
    *   This function only called by token contract.
    */
    function requestDividendPayment(uint256 dividendAmount) public returns(bool) {

        require(msg.sender == topiaTokenContractAddress, 'Unauthorised caller');
        dividendPaidAllTime += dividendAmount; //no safemath used as underflow is impossible, and it saves some energy
        msg.sender.transfer(dividendAmount);

        return true;

    }

    /**
        Function to update dividend threshold
    */
    function updateDividendThreshold(uint256 _dividendThreshold) public onlyOwner returns(string){
        
        require(_dividendThreshold > 0, 'Invalid Amount');
        dividendThreshold = _dividendThreshold;

        return "Dividend threshold updated";
    }

}