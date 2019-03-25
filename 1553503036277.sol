pragma solidity ^0.4.25;

contract BeanPot{
    uint seed=0;
    
    struct  UserInfo{
        uint seeds;
        uint purchaseTime;
        uint irrigationTime;
        uint irrigationCount;
        bool irgtInTime;
    }
   
    mapping(address=>UserInfo) accounts;
    
    event  UserInfos(
        uint seeds,
        uint purchaseTime,
        uint irrigationTime,
        uint irrigationCount,
        bool irgtInTime
    );
    
    event totalSeeds(
        uint indexed seed
        );
    
    modifier SeedPrice(){
        require (msg.value >= 50000);
        _;
    }
    
    modifier planting(){
        UserInfo memory v = accounts[msg.sender];
        require (v.seeds >= 10 && v.irrigationCount == 0);
        _;
    }
    
    modifier irrigationPeriod(){
        UserInfo memory v = accounts[msg.sender];
        require ((v.irgtInTime == false) || ((now >= v.irrigationTime+ 1 minutes) && (now <= v.irrigationTime + 2 minutes)));
        
        _;
    }
    
    
    function BuySeed() public payable SeedPrice returns(bool){
        UserInfo storage u = accounts[msg.sender];
        u.seeds += msg.value/5000;
        u.purchaseTime = now;
        u.irgtInTime = false;
        seed += msg.value/5000;
        UserInfo memory v = accounts[msg.sender];
        emit UserInfos(v.seeds, v.purchaseTime, v.irrigationTime, v.irrigationCount, v.irgtInTime);
        emit totalSeeds(seed);
        return true;
    }
    
    function plantSeeds() public returns(bool){
       UserInfo storage u = accounts[msg.sender];
        u.irrigationTime = now + 2 minutes;
        u.irrigationCount ++;
        u.irgtInTime = true;
        u.seeds -= 10;
        UserInfo memory v = accounts[msg.sender];
        emit UserInfos(v.seeds, v.purchaseTime, v.irrigationTime, v.irrigationCount, v.irgtInTime);
        return true; 
    }
    
    function Irrigation() public irrigationPeriod returns(bool){
        UserInfo storage u = accounts[msg.sender];
        u.irrigationTime= now + 2 minutes;
        u.irrigationCount++;
        u.irgtInTime=true;
        u.seeds+=2;
        UserInfo memory v = accounts[msg.sender];
        emit UserInfos(v.seeds, v.purchaseTime, v.irrigationTime, v.irrigationCount, v.irgtInTime);
        return true;    
    }
   
    function resetMyPot() public returns(uint){
        UserInfo memory v = accounts[msg.sender];
        if(now> v.irrigationTime+2 minutes){
            UserInfo storage u = accounts[msg.sender];
            u.irrigationTime = 0;
            u.irrigationCount = 0;
            u.irgtInTime = false;
        }
        return (v.irrigationCount);
        emit UserInfos(v.seeds, v.purchaseTime, v.irrigationTime, v.irrigationCount, v.irgtInTime);
    }
    
    function GetUserInfo(address adrs) public view returns (uint,uint,uint,uint,bool){
        UserInfo memory u = accounts[adrs];
        return (u.seeds, u.purchaseTime, u.irrigationTime, u.irrigationCount, u.irgtInTime);
    }
    
    function GetThisUserInfo() public view returns (uint,uint,uint,uint,bool){
        UserInfo memory u = accounts[msg.sender];
        return (u.seeds, u.purchaseTime, u.irrigationTime, u.irrigationCount, u.irgtInTime);
    }
    
    function SeedsSoldByNow() public view returns (uint){
        return seed;
    } 
}