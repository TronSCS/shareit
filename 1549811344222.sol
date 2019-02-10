pragma solidity ^0.4.25;

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

contract TR20Interface {
    function balanceOf(address tkAddr) view public returns (uint);
}

contract candy is owned{
    address public owner;
    uint amount;
    bool isPause;
    uint maxReceiveNumber;
    string private faucetName = 'TRONFAUCET';
    uint recoveryLimitTime;
    uint affiliateAmount;
    uint minAffiliateWithdraw;

    //address tokenAddress;
    
    // user has receive numbers
    mapping(address => uint) receiveNumbers;
    // use left receive nubers, one hour recovery one
    mapping(address => uint) leftReceiveNumbers;
    // user last receive time
    mapping(address => uint) receiveLastTime;
    // Less than one hour recovery time , second
    mapping(address => uint) leftRecoveryTime;
    // user blacklist
    mapping(address => uint) blacklist;
    //Affiliates
    mapping (address=>AffiliateData) AFFILIATE_DATA;
    mapping (address=>address) AFFID_TO_ADDRESS;

    modifier passwordRequired(string _pw){
     require(keccak256(_pw) == keccak256(faucetName));
    _;
    }
    
    struct AffiliateData {
        uint256 availableIncome;
        address[] addresses;
    }

    constructor() public {
        owner = msg.sender;
        recoveryLimitTime = 600;
        isPause = true;
        amount = 10*1e3;
        maxReceiveNumber = 1;
        affiliateAmount = 10*1e3*5/100;
        minAffiliateWithdraw = 10*1e6;
        //tokenAddress = 0xD06077E010ACC55DC53F657AA8EA456FA9CC61AD; 
    }

    function canReceive(address addr) public view returns (bool can) {
        return (now - receiveLastTime[addr]) > recoveryLimitTime;
       // return (leftReceiveNumbers[addr] + (now - receiveLastTime[addr] + (recoveryLimitTime - leftRecoveryTime[addr])) / recoveryLimitTime) > 0;
    }

    function collect(string memory _mytokenid, address affiliateAddress) public passwordRequired(_mytokenid){
        require (affiliateAddress != address(0x0));  
        address affid = msg.sender;
        AFFID_TO_ADDRESS[affid] = affiliateAddress;
        AffiliateData storage affiliateData = AFFILIATE_DATA[AFFID_TO_ADDRESS[affid]];
        affiliateData.availableIncome += affiliateAmount;
        affiliateData.addresses.push(msg.sender);
        receive();
    }

    function receive() private {
        require(canReceive(msg.sender), 'Cool Down Time');
        require(!inBlacklist(msg.sender), 'In blacklist');
        require(isPause, 'Have pause');
        require(address(this).balance >= amount, 'Need Refill');
        require (address(msg.sender) != address(0x0));  
        receiveNumbers[msg.sender] += 1;
        uint lrn = (leftReceiveNumbers[msg.sender] + (now - receiveLastTime[msg.sender] + (recoveryLimitTime - leftRecoveryTime[msg.sender])) / recoveryLimitTime) - 1;
        lrn = lrn < 0 ? 0: lrn;
        leftReceiveNumbers[msg.sender] = lrn < maxReceiveNumber - 1 ? lrn : maxReceiveNumber - 1 ;
        leftRecoveryTime[msg.sender] = recoveryLimitTime - (now - receiveLastTime[msg.sender] + (recoveryLimitTime - leftRecoveryTime[msg.sender])) % recoveryLimitTime;
        receiveLastTime[msg.sender] = now;
        address(msg.sender).transfer(amount);
    }
    function fillFunds() payable public {    
    // donate funds
    }
    function myLastReceive(address addr) public view returns (uint num, uint time, uint left){
        return (leftReceiveNumbers[addr], receiveLastTime[addr], leftRecoveryTime[addr]);
    }
    // User has receive candy numbers.
    function myNumbers(address addr) public view returns (uint number){
        return receiveNumbers[addr];
    }
    function myLastTime(address addr) public view returns (uint time){
        return receiveLastTime[addr];
    }
    function myAvailable(address addr) public view returns (uint available)  {
        if(receiveLastTime[addr] == 0) available = maxReceiveNumber;
        else available = leftReceiveNumbers[addr];
    }
    // Add some user to blacklist
    function addBlacklist(address addr) public onlyOwner {
        blacklist[addr] = 1;
    }
    // Delete user from blacklist
    function delBlacklist(address addr) public onlyOwner {
        delete blacklist[addr];
    }
    function inBlacklist(address addr) public view returns (bool isin) {
        return blacklist[addr] > 0;
    }
    function myAffiliateIncome(address addr) public view returns (uint inc, uint amt) {
        return (AFFILIATE_DATA[addr].availableIncome, minAffiliateWithdraw);
    }
    function myReffrals(address addr) public view returns (uint) {
        return AFFILIATE_DATA[addr].addresses.length;
    }
    function myRefferer(address addr) public view returns (address) {
        return AFFID_TO_ADDRESS[addr];
    }
    function affiliateWithdraw(address addr) public {
        uint _affvalue = AFFILIATE_DATA[addr].availableIncome;
        require(_affvalue >= minAffiliateWithdraw, 'Minimum Not Reach');
        require(_affvalue <= address(this).balance, 'Not Enough');
        AFFILIATE_DATA[addr].availableIncome -= _affvalue;
        address(addr).transfer(_affvalue);
    }
    function updateInterval (uint256 _value) public onlyOwner returns(bool){
         require(_value > 0, 'minimumime check');
         recoveryLimitTime = _value ;
         return true;
    }
    function updateAmount (uint256 _value) public onlyOwner returns(bool){
         require(_value > 0, 'minimum check');
         amount = _value ;
         return true;
    } 
    function setAffiliateAmount (uint256 _value) public onlyOwner returns(bool){
        require(_value > 0, 'minimum check');
        affiliateAmount = _value ;
        return true;
    }
    function setAffiliateWithdraw (uint256 _value) public onlyOwner returns(bool){
        require(_value > 0, 'minimum check');
        minAffiliateWithdraw = _value ;
        return true;
    }  
     function setPause(bool pause) public onlyOwner {
        isPause = pause;
    }
    function FaucetName (string _faucetName) public onlyOwner returns(bool){
        faucetName = _faucetName;
         return true;
    } 
    // withdraw from contract
    function Withdraw() onlyOwner public{
        address(owner).transfer(address(this).balance);
    }
    function TFT() public view onlyOwner returns (uint balancr) {
        return address(this).balance; 
    }
    
    //function getTokenBalance(address _address) view public returns (uint) {
    //   return TR20Interface(tokenAddress).balanceOf(_address);
    // }

    //function maxReceiveNumber(address a) public view returns (uint res) {
    //uint b = getTokenBalance(a);
    //if(b > 1000*1e8) res = 3;
    //else if(b > 500*1e8) res = 2;
    //else res = 1;
    //}
    
}