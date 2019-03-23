pragma solidity 0.4.25;

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
    uint256 nonce = 0;
    address private mainContractAddress = address(this);
    address public topiaTokenContractAddress;
    
    uint256 public decimals = 8;

    bytes32 private _yin = bytes32("yin");
    bytes32 private _yang = bytes32("yang");
    bytes32 private _bang = bytes32("bang");
    bytes32 private _zero = bytes32("zero");
    bytes32 private _odd = bytes32("odd");
    bytes32 private _even = bytes32("even");

    uint256 private yinMultiplier = 21111;
    uint256 private yangMultiplier = 21111;
    uint256 private bangMultiplier = 95000;
    uint256 private zeroMultiplier = 950000;
    uint256 private oddMultiplier = 19000;
    uint256 private evenMultiplier = 19000;

    uint256 private tronDecimals=6;
    uint256 public betPrice = 10 * (10**tronDecimals);                   //10 TRX for 1 bet
    uint256 public TotalBetsMade =0;
    uint256 public TotalWinAmount =0;
    uint256 public minimumTokenRequirement = 100 * (10**decimals);     //User must have at least 100 Tokens to be eligible to receive winnings
    uint256 public poolMinimumRequirement = 1000000 * (10**tronDecimals);  //1 Million
               
    uint256 range;
    uint256 multiplier;
    uint256 firstNumber;
    uint256 lastNumber;
    uint256 private mToken;
    uint256 public totalReferralBonusPaid;
    uint256 public maxBetAmount = 500000;
    uint256 public maxWinDivisibleAmount = 50;

    
    event Roll(address indexed user, uint _startNumber, uint _endNumber, uint _winningNumber, uint256 _value, bool result,uint256 timestamp);
    event KingTopian(address indexed user, uint256 _prize, uint256 _trxplayed, uint256 timestamp);
    event UnluckyBunch(address indexed user, uint256 _loose, uint256 _trxplayed, uint256 timestamp);
    event HighRollers(address indexed user, uint _startNumber, uint _endNumber, uint _winningNumber, uint256 _value, uint256 _winamount, bool result,uint256 timestamp);
    event RareWins(address indexed user, uint _startNumber, uint _endNumber, uint _winningNumber, uint256 _value, uint256 _winamount, bool result,uint256 timestamp);
    event SideBetRolls(address indexed user, uint _winningNumber, uint256 _betValue, uint256 winAmount, bytes32 sideBet, bool result,uint256 timestamp);
    //event SideBetWins(address indexed user, uint _winningNumber, uint256 _betValue, uint256 winAmount, string sideBet, bool result,uint256 timestamp);
    

    /**
        * Fallback function. It just accepts incoming TRX
    */
    function () payable external {}

    /*generate random hash seed */
    function getSeed() public view returns(bytes memory){
        return abi.encodePacked(now);
    }


    //addMultiplier to store multiplier array data in contract
    /** Following array must be put as input

        [985000,492500,328333,246250,197000,164166,140714,123125,109444,98500,89545,82083,75769,70357,65666,61562,57941,54722,51842,49250,46904,44772,42826,41041,39400,37884,36481,35178,33965,32833,31774,30781,29848,28970,28142,27361,26621,25921,25256,24625,24024,23452,22906,22386,21888,21413,20957,20520,20102,19700,19313,18942,18584,18240,17909,17589,17280,16982,16694,16416,16147,15887,15634,15390,15153,14924,14701,14485,14275,14071,13873,13680,13493,13310,13133,12960,12792,12628,12468,12312,12160,12012,11867,11726,11588,11453,11321,11193,11067,10944,10824,10706,10591,10478,10368,10260,10155]

    */
    function addMultiplier (uint256[] memory data) public onlyOwner returns(string){
        multipliersData = data;
        return "Multiplier Added";
    }


    function xxxx (uint256[] rollIntegerVariables, bytes32[] rollBytes32Variables, address _referrer) public returns(bool){
        return roll( rollIntegerVariables,  rollBytes32Variables, _referrer);
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
    * 
    * bytes32[] rollBytes32Variables array contains
    * rollBytes32Variables[0] = _seedPlayer;
    * rollBytes32Variables[1] = _seedSigner;
    * rollBytes32Variables[2] = _sideBetName;
    * 
    */
    function roll(uint256[] rollIntegerVariables, bytes32[] rollBytes32Variables, address _referrer) payable public returns(bool) {

        //checking conditions
        if(msg.value != (rollIntegerVariables[2]+rollIntegerVariables[3]) * (10 ** tronDecimals)) return false;
        if(rollIntegerVariables[2] > maxBetAmount) return false;
        if(rollIntegerVariables[1] < rollIntegerVariables[0]) return false;

        uint256 _winningNumber = random(rollBytes32Variables[0]);
        uint256 sideBetsWin = 0;
        uint256 winamount = 0;
        bool _sideBetStatus = false;
        TRONtopiaInterface tronTopiaContract = TRONtopiaInterface(topiaTokenContractAddress);
        address _referrerInMapping = tronTopiaContract.referrers(msg.sender);
        TotalBetsMade++;
        
        // mint tokens depending on how much TRX is received
        tronTopiaContract.mintToken(msg.sender, msg.value);

        // finding sidebets code START --------------------------------------------------------->> 
        if(rollBytes32Variables[2] != bytes32(0)){
            
            firstNumber = _winningNumber / 10;
            lastNumber = _winningNumber - (firstNumber * 10);
            
            if( rollBytes32Variables[2] == _yin ){
                
                if(firstNumber>lastNumber){
                    _sideBetStatus = true;
                    sideBetsWin = rollIntegerVariables[3] * yinMultiplier * 100;
                }        
            }
            else if( rollBytes32Variables[2] == _yang ){
                
                if(firstNumber<lastNumber){
                    _sideBetStatus = true; 
                    sideBetsWin = rollIntegerVariables[3] * yangMultiplier * 100;
                }                   
            }
            else if( rollBytes32Variables[2] == _bang ){
                if (_winningNumber == 0 || _winningNumber == 11 || _winningNumber == 22 || _winningNumber == 33 || _winningNumber == 44 || _winningNumber == 55 || _winningNumber == 66 || _winningNumber == 77 || _winningNumber == 88 || _winningNumber == 99) {
                    _sideBetStatus = true; 
                    sideBetsWin = rollIntegerVariables[3] * bangMultiplier * 100;
                }                   
            }
            else if( rollBytes32Variables[2] == _zero ){
                if (_winningNumber == 0  ) {
                    _sideBetStatus = true; 
                    sideBetsWin = rollIntegerVariables[3] * zeroMultiplier * 100;
                }                
            }
            else if( rollBytes32Variables[2] == _odd ){
                if (_winningNumber % 2 != 0  ) {
                    _sideBetStatus = true; 
                    sideBetsWin = rollIntegerVariables[3] * oddMultiplier * 100;
                }
            }
            else if( rollBytes32Variables[2] == _even ){
                if (_winningNumber % 2 == 0  ) {
                    _sideBetStatus = true;
                        sideBetsWin = rollIntegerVariables[3] * evenMultiplier * 100;   
                }    
                                                    
            }
        }
        // finding sidebets code END --------------------------------------------------------->>


        // finding main bet winning code START ------------------------------------------------->>
        if(_winningNumber>=rollIntegerVariables[0] && _winningNumber<=rollIntegerVariables[1]){
            range = rollIntegerVariables[1] - rollIntegerVariables[0];
            if(range==0){
                multiplier = multipliersData[range];
            }else{
                multiplier = multipliersData[range--];
            }
            winamount = rollIntegerVariables[2] * multiplier * 100;  
        }
        // finding main bet winning code START ------------------------------------------------->>


        // we want to restrict that winning of TRX can not be higher than TRX balance of contract / 50
        // totalWinning TRX (which is: sideBetsWin + winamount) - input TRX amount <= contract balance / 50
        // we are aware that if sideBetsWin and winamount will be zero, then it will produce overflow, so making condition
        if(sideBetsWin + winamount >= rollIntegerVariables[2] * 1e6){
            if(sideBetsWin + winamount - (rollIntegerVariables[2] * 1e6 ) > address(this).balance / maxWinDivisibleAmount) return false;
        }

        if(_sideBetStatus){
            TotalWinAmount += sideBetsWin;
            emit SideBetRolls(msg.sender, _winningNumber, rollIntegerVariables[3],  sideBetsWin, rollBytes32Variables[2], _sideBetStatus, now); 
        } 

        if(_winningNumber>=rollIntegerVariables[0] && _winningNumber<=rollIntegerVariables[1]){
            
            uint256 _refBonus = winamount * 2 / 1000;
            totalReferralBonusPaid += _refBonus;
            TotalWinAmount +=  winamount;
            
            /** Processing referral system fund distribution **/
            // [✓] 0.2% trx to referral if any.

            // Case 1: player have used referral links
            if(_referrer != address(0) && _referrerInMapping != address(0)){
                tronTopiaContract.payReferrerBonusOnly(msg.sender, _refBonus, msg.value );
            }
            
            // Case 2: player has existing referrer/up-line/direct sponsor, but he did not use any referrer link or sent trx directly to smart contract
            // In this case, trx will be sent to existing referrer
            else if(_referrer == address(0) && _referrerInMapping != address(0)){
                tronTopiaContract.payReferrerBonusOnly(msg.sender, _refBonus, msg.value );
            }
            
            // Case 3: depositor does not have any existing direct referrer, but used referral link
            // In this case, referral bonus will be paid to address in the referral link
            else if(_referrer != address(0) && _referrerInMapping == address(0)){
                tronTopiaContract.payReferrerBonusAndAddReferrer(msg.sender, _referrer, msg.value, _refBonus);
            }
            
            else {
                //nothing to do
            }

                        
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
            if(_referrer != address(0x0) && _referrerInMapping == address(0x0)){
                //adding referral details in referrer mapping in topiaContract
                tronTopiaContract.updateReferrer(msg.sender, _referrer);
            }
            emit UnluckyBunch(msg.sender, rollIntegerVariables[2], rollIntegerVariables[2], now);
            emit Roll(msg.sender, rollIntegerVariables[0], rollIntegerVariables[1], _winningNumber, rollIntegerVariables[2], false, now);
        }
        if(winamount + sideBetsWin > 0){
            msg.sender.transfer(winamount + sideBetsWin);
        }
        return true;
    }


    //function to generate random number
    function random(bytes32 seed) internal returns (uint) {
            uint randomnumber = uint(keccak256(abi.encodePacked(now, msg.sender, nonce, seed))) % 99;
            randomnumber = randomnumber;
            nonce++;
            return randomnumber;
    }

    function isContract(address _address) public view returns (bool){
        uint32 size;
        assembly {
            size := extcodesize(_address)
        }
        return (size > 0);
    }
    


    function totalTRXbalanceContract() public view returns(uint256){
        return address(this).balance;
    }

    //Just in rare case, owner wants to transfer TRX and Tokens from contract to owner address
    function manualWithdrawTRX(uint256 amount)onlyOwner public{
        address(owner).transfer(amount);
    }
    
    function manualWithdrawTokens(uint256 tokenAmount) public onlyOwner{
        // no need for overflow checking as that will be done in transfer function
        //_transfer(address(this), owner, tokenAmount);
        bytes memory transferData = abi.encodeWithSignature("transfer(address,uint256)",owner,tokenAmount);
        require(topiaTokenContractAddress.call.gas(200000)(transferData), 'Transfer function did not work');
            
    }

    function updateTopiaTokenContractAddress(address _newAddress) public onlyOwner returns(string){
        
        require(_newAddress != address(0), 'Invalid Address');

        topiaTokenContractAddress = _newAddress;

        return "Topia Token Contract Address Updated";
    }

    function updateSidebetMultipliers(uint256 yinMultiplier_, uint256 yangMultiplier_, uint256 bangMultiplier_, uint256 zeroMultiplier_, uint256 oddMultiplier_, uint256 evenMultiplier_  ) public onlyOwner returns(string){
        
        yinMultiplier = yinMultiplier_;
        yangMultiplier = yangMultiplier_;
        bangMultiplier = bangMultiplier_;
        zeroMultiplier = zeroMultiplier_;
        oddMultiplier = oddMultiplier_;
        evenMultiplier = evenMultiplier_;

        return("side bet multipliers updated successfully");
    }

    function updateMaxBetMaxWin(uint256 maxBetAmount_, uint256 maxWinDivisibleAmount_  ) public onlyOwner returns(string){
        
        maxBetAmount = maxBetAmount_;
        maxWinDivisibleAmount = maxWinDivisibleAmount_;

        return("Max bet and max win updated successfully");
    }


    

    //-------------------------------------------------//
    //---------------- DIVIDEND SECTION ---------------//
    //-------------------------------------------------//

    uint256 public dividendThreshold = 500000 * (10**tronDecimals); //500,000 TRX dividend threshold
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

     
    function updateDividendThreshold(uint256 _dividendThreshold) public onlyOwner returns(string){
        
        require(_dividendThreshold > 0, 'Invalid Amount');

        dividendThreshold = _dividendThreshold;

        return "Dividend threshold updated";
    }




}