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
    string internal yin = 'yin';
    string internal yang = 'yang';
    string internal bang = 'bang';
    string internal zero = 'zero';
    string internal odd = 'odd';
    string internal even = 'even';
    uint256 private yinMultiplier = 21111;
    uint256 private yangMultiplier = 21111;
    uint256 private bangMultiplier = 95000;
    uint256 private zeroMultiplier = 950000;
    uint256 private oddMultiplier = 19000;
    uint256 private evenMultiplier = 19000;

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
    uint256 totalReferralBonusPaid;

    
    
    
    
    event Roll(address indexed user, uint _startNumber, uint _endNumber, uint _winningNumber, uint256 _value, bool result,uint256 timestamp);
    event KingTopian(address indexed user, uint256 _prize, uint256 _trxplayed, uint256 timestamp);
    event UnluckyBunch(address indexed user, uint256 _loose, uint256 _trxplayed, uint256 timestamp);
    event HighRollers(address indexed user, uint _startNumber, uint _endNumber, uint _winningNumber, uint256 _value, uint256 _winamount, bool result,uint256 timestamp);
    event RareWins(address indexed user, uint _startNumber, uint _endNumber, uint _winningNumber, uint256 _value, uint256 _winamount, bool result,uint256 timestamp);
    event SideBetRolls(address indexed user, uint _winningNumber, uint256 _betValue, uint256 winAmount, string sideBet, bool result,uint256 timestamp);
    //event SideBetWins(address indexed user, uint _winningNumber, uint256 _betValue, uint256 winAmount, string sideBet, bool result,uint256 timestamp);
    


    
    
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

   
    
    //function to roll dice and win or loose game
    function roll(uint _startNumber,uint _endNumber,uint _amount, bytes32 _seed, address _referrer, string _sideBet, uint256 _sideBetvalue) payable public returns(bool, uint256, bool, uint256) {

            require(msg.value == (_amount+_sideBetvalue) * (10 ** tronDecimals), 'Invalid _amount');
            require(_seed !=bytes32(0), 'Invalid _seed');
            require(_amount <= 500000, 'Bet amount too large');

            _winningNumber = random(_seed);
            range = _endNumber-_startNumber;
            bytes memory _sideBetM = bytes(_sideBet);
            
            _sideBetStatus = false;
            TotalBetsMade++;
            
            //require(topiaTokenContractAddress.call.gas(100000)(abi.encodeWithSignature("mintToken(address,uint256)",msg.sender,msg.value)), 'MintToken function did not work');
            TRONtopiaInterface(topiaTokenContractAddress).mintToken(msg.sender, msg.value);

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
                else if(keccak256(_sideBetM) == keccak256(_yang)){
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
                else if(keccak256(_sideBetM) == keccak256(_bang)){
                     if (_winningNumber == 0 || _winningNumber == 11 || _winningNumber == 22 || _winningNumber == 33 || _winningNumber == 44 || _winningNumber == 55 || _winningNumber == 66 || _winningNumber == 77 || _winningNumber == 88 || _winningNumber == 99) {
                       _sideBetStatus = true; 
                        sideBetsWin = _sideBetvalue.mul(bangMultiplier);
                        sideBetsWin = sideBetsWin.mul(100);
                        TotalWinAmount = TotalWinAmount.add(sideBetsWin);
                        msg.sender.transfer(sideBetsWin);
                        
                    } 
                    emit SideBetRolls(msg.sender, _winningNumber, _sideBetvalue,  sideBetsWin, _sideBet, _sideBetStatus, now);                    
                }
                else if(keccak256(_sideBetM) == keccak256(_zero)){
                    if (_winningNumber == 0  ) {
                       _sideBetStatus = true; 
                        sideBetsWin = _sideBetvalue.mul(zeroMultiplier);
                        sideBetsWin = sideBetsWin.mul(100);
                        TotalWinAmount = TotalWinAmount.add(sideBetsWin);
                        msg.sender.transfer(sideBetsWin);
                    }
                    emit SideBetRolls(msg.sender, _winningNumber, _sideBetvalue,  sideBetsWin, _sideBet, _sideBetStatus, now);                    
                }
                else if(keccak256(_sideBetM) == keccak256(_odd)){
                    if (_winningNumber % 2 != 0  ) {
                       _sideBetStatus = true; 
                        sideBetsWin = _sideBetvalue.mul(oddMultiplier);
                        sideBetsWin = sideBetsWin.mul(100);
                        TotalWinAmount = TotalWinAmount.add(sideBetsWin);
                        msg.sender.transfer(sideBetsWin);
                    }
                    emit SideBetRolls(msg.sender, _winningNumber, _sideBetvalue,  sideBetsWin, _sideBet, _sideBetStatus, now);                    
                }
                else if(keccak256(_sideBetM) == keccak256(_even)){
                    if (_winningNumber % 2 == 0  ) {
                        _sideBetStatus = true;
                         sideBetsWin = _sideBetvalue.mul(evenMultiplier);
                         sideBetsWin = sideBetsWin.mul(100);
                         TotalWinAmount = TotalWinAmount.add(sideBetsWin);
                         msg.sender.transfer(sideBetsWin);
                    }    
                    emit SideBetRolls(msg.sender, _winningNumber, _sideBetvalue,  sideBetsWin, _sideBet, _sideBetStatus, now);                                    
                }

            address _referrerInMapping = TRONtopiaInterface(topiaTokenContractAddress).referrers(msg.sender);

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
                if(_referrer != address(0x0) && _referrerInMapping != address(0x0)){
                    _refBonus = winamount.mul(2).div(1000);
                    //referrerBonusBalance[referrers[msg.sender]] += _refBonus;  //0.2% of winamount
                    TRONtopiaInterface(topiaTokenContractAddress).payReferrerBonusOnly(msg.sender, _refBonus, msg.value );
                    winamount = winamount.sub(_refBonus);
                    totalReferralBonusPaid += _refBonus;
                }
                
                // Case 2: player has existing referrer/up-line/direct sponsor, but he did not use any referrer link or sent trx directly to smart contract
                // In this case, trx will be sent to existing referrer
                else if(_referrer == address(0x0) && _referrerInMapping != address(0x0)){
                    _refBonus = winamount.mul(2).div(1000);
                    //referrerBonusBalance[referrers[msg.sender]] += _refBonus;  //0.2% of winamount 
                    TRONtopiaInterface(topiaTokenContractAddress).payReferrerBonusOnly(msg.sender, _refBonus, msg.value );
                    winamount = winamount.sub(_refBonus);
                    totalReferralBonusPaid += _refBonus;
                }
                
                // Case 3: depositor does not have any existing direct referrer, but used referral link
                // In this case, referral bonus will be paid to address in the referral link
                else if(_referrer != address(0x0) && _referrerInMapping == address(0x0)){
                    _refBonus = winamount.mul(2).div(1000);
                    //referrerBonusBalance[_referrer] += _refBonus;  //0.2% of winamount 
                    TRONtopiaInterface(topiaTokenContractAddress).payReferrerBonusAndAddReferrer(msg.sender, _referrer, msg.value, _refBonus);
                    winamount = winamount.sub(_refBonus);
                    totalReferralBonusPaid += _refBonus;
                }
                
                // All other cases apart from above, referral bonus will not be paid to anyone
                // And Entire platform fee (5% of deposit) will be sent to stock contract
                else {
                    //nothing to do
                }

              
                msg.sender.transfer(winamount2);

                // we want to restrict that token output of TRX can not be higher than TRX balance of contract
                // totalWinning TRX (which is: sideBetsWin + winamount2) - input TRX amount <= contract balance / 50
                
                require(sideBetsWin + winamount2 - (_amount * 1e6 ) <= address(this).balance / 50, 'Win amount exceeds maximum limit');

                
                emit Roll(msg.sender,_startNumber, _endNumber, _winningNumber, _amount, true, now);
                emit KingTopian(msg.sender, winamount2, _amount, now);

                if(_amount>10000){
                    emit HighRollers(msg.sender,_startNumber, _endNumber, _winningNumber, _amount, winamount2, true, now);
                }
                if(range<5){
                    emit RareWins(msg.sender,_startNumber, _endNumber, _winningNumber, _amount, winamount2, true, now);
                }

                return (true,_winningNumber,_sideBetStatus, sideBetsWin + winamount2 - (_amount * 1e6));
            }else{
                 
                if(_referrer != address(0x0) && _referrerInMapping == address(0x0)){
                    //adding referral details in referrer mapping in topiaContract
                    //referrers[msg.sender]=_referrer;
                    TRONtopiaInterface(topiaTokenContractAddress).updateReferrer(msg.sender, _referrer);
                }
                 
                 emit UnluckyBunch(msg.sender, _amount, _amount, now);
                 emit Roll(msg.sender, _startNumber, _endNumber, _winningNumber, _amount, false, now);
                 return (false,_winningNumber,_sideBetStatus, msg.value );
            }
    }
    //function to generate random number
    function random(bytes32 seed) internal returns (uint) {
            uint randomnumber = uint(keccak256(abi.encodePacked(now, msg.sender, nonce, seed))) % 99;
            randomnumber = randomnumber;
            nonce++;
            return randomnumber;
    }


    function totalTRXbalanceContract() public view returns(uint256){
        return address(this).balance;
    }

    //Just in rare case, owner wants to transfer TRX and Tokens from contract to owner address
    function manualWithdrawTRX()onlyOwner public{
        address(owner).transfer(address(this).balance);
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

}