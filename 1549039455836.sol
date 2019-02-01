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
    function balanceOf(address addre) view public returns (uint);
}

contract candy is owned{
    address public owner;
    uint amount;
    bool isPause;
    //address public tokenAddress;
    address tokenAddress;
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
        
        maxReceiveNumber = 1;
        tokenAddress = 0xD06077E010ACC55DC53F657AA8EA456FA9CC61AD;
        owner = msg.sender;
        recoveryLimitTime = 600;
        isPause = true;
        amount = 10*1e3;
        //TR20Interface token = TR20Interface(tokenAddress);
        //uint deployerBalance = token.balanceOf(msg.sender);
        //if(deployerBalance > 1000) maxReceiveNumber = 3;
        //else if(deployerBalance < 1000 && deployerBalance > 500) maxReceiveNumber = 2;
        //else maxReceiveNumber = 1;
        
    }
    function getTR20Balance(address _address) view public returns (uint) {
       return TR20Interface(tokenAddress).balanceOf(_address);
     }
    //function maxReceiveNumber(address a) public view returns (uint res) {
    //uint b = getTR20Balance(a);

    //if(b > 1000) res = 3;
    //else if(b > 500) res = 2;
    //else res = 1;
    //}

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