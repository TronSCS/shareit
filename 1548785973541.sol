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

contract candy is owned{
    address public owner;
    uint amount;
    bool isPause;
    // recovery limit time 3600 second
    uint recoveryLimitTime;
    // Maximum number of users available.
    uint maxReceiveNumber;
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
    mapping(address => uint) public balanceOf;
    
    constructor() public {
        owner = msg.sender;
        maxReceiveNumber = 1;
        recoveryLimitTime = 600;
        isPause = true;
        amount = 10*1e3;
    }
    
    function receive() payable public{
        require(canReceive(msg.sender), 'should wait one hour');
        require(!inBlacklist(msg.sender), 'In blacklist');
        require(isPause, 'Have pause');
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
    function canReceive(address addr) public view returns (bool can) {
        return (leftReceiveNumbers[addr] + (now - receiveLastTime[addr] + (recoveryLimitTime - leftRecoveryTime[addr])) / recoveryLimitTime) > 0;
    }
    function myLastReceive(address addr) public view returns (uint num, uint time, uint left){
        return (leftReceiveNumbers[addr], receiveLastTime[addr], leftRecoveryTime[addr]);
    }
    function maxNumbers() public view returns (uint number){
        return maxReceiveNumber;
    }
    // User has receive candy numbers.
    function myNumbers(address addr) public view returns (uint number){
        return receiveNumbers[addr];
    }
    function myAvailable(address addr) public view returns (uint number){
        return leftReceiveNumbers[addr];
        
    }
    function myLastTime(address addr) public view returns (uint time){
        return receiveLastTime[addr];
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
    function updateInterval (uint256 _value) public onlyOwner returns(bool){
         require(_value > 0, 'minimumime check');
         recoveryLimitTime = _value ;
         return true;
     }
    function updateMaxNumbers (uint256 _value) public onlyOwner returns(bool){
         require(_value > 0, 'minimumime check');
         maxReceiveNumber = _value ;
         return true;
     } 
    function updateAmount (uint256 _value) public onlyOwner returns(bool){
         require(_value > 0, 'minimumime check');
         amount = _value ;
         return true;
     } 
     function setPause(bool pause) public onlyOwner {
        isPause = pause;
    }
    // withdraw from cintract
    function manualWithdrawTron()onlyOwner public{
        address(owner).transfer(address(this).balance);
    }

}