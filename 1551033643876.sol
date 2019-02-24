pragma solidity ^0.4.25;

contract Account{
  
  address bank;
  constructor(address _bank) public{
    bank = HotWallet(_bank);
  }
  function pull() external{
    require(msg.sender==address(bank));
    msg.sender.transfer(address(this).balance);
  }
  
  function () payable{
      
  }
}


contract HotWallet {
  
  uint COLD_HOT_FACTOR ;
  uint BLOCK_WAIT_PAUSE ;
  address coldWallet ;
  bool locked = false;
  mapping(bytes32=>uint) pendingTransfers;

  modifier isUnlocked{

    require(locked==false);
    _;
  }
  
  
  function () payable{
      
  }
  
  function send(address _x) payable{
      _x.transfer(msg.value);
  }


  constructor(address _cold, uint _cold_hot_factor,uint _blockPause) public{
    coldWallet = _cold; 
    COLD_HOT_FACTOR = _cold_hot_factor;
    BLOCK_WAIT_PAUSE = _blockPause;

  }
  
  /*TODO Brak funkcji administracyjnych */
  
  /*locks withdraw - an emergency break, can be invoked only by special account*/
//  function lock(uint nonce);
  
  /*reverse effects of lock, needs multiple signatures of legalLockAccounts of message keccak256(abi.encodePacked("lock()",nonce));*/
// function unlock(uint nonce ,bytes32[] memory r,bytes32[] memory s,byte[] memory v);
  
   function transferDeposit(address adr) public{
      uint _balance = address(adr).balance;
      Account(adr).pull();
      emit FundsDeposited(adr,_balance);
   }
  
  function sendBalanceToCold() public{
    uint _coldBalance = address(coldWallet).balance;
    uint _hotBalance = address(this).balance;

    if(_hotBalance>_coldBalance/10){
      coldWallet.transfer(_hotBalance-_coldBalance/10);
    }

  }

  /*creates new account if no accounts in unassignedAccoutns otherwise takes from there*/
  function createNewAccount() public{
    emit AccountCreated(address(new Account(address(this))));
  }

  function withdraw(address[] memory destination,uint[] memory sum) public isUnlocked{
    if(pendingTransfers[keccak256(abi.encodePacked(destination,sum))]==0){
      pendingTransfers[keccak256(abi.encodePacked(destination,sum))]=block.number;
    }else{
      require(block.number-BLOCK_WAIT_PAUSE>=pendingTransfers[keccak256(abi.encodePacked(destination,sum))],"to little blocks passed");
      for(uint i=0;i<destination.length;i++){
        destination[i].transfer(sum[i]);
        emit WithdrawMade(destination[i],sum[i]);
      }
    }

  }
  event AccountCreated(address target);
  event FundsDeposited(address userId, uint256 sum);
  event WithdrawMade(address target,uint256 sum);
  
  
}