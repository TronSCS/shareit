pragma solidity ^0.4.24;

contract MeeChat {
  
  uint constant MIN_AMOUNT = 0.01 ether;
  uint constant MAX_AMOUNT = 1000000 ether;
  
  address public owner;
  
  uint internal redpackId_ = 0;
  
  event FailedPayment(address indexed beneficiary, uint amount);
  event Payment(address indexed beneficiary, uint amount);
  
  function getRedpackInfo(uint id) external view returns (
  uint redpackId,
  address sender,
  address[] memory receiver,
  uint8 totalNumber,
  uint8 leftNumber,
  uint totalAmount,
  uint leftAmount,
  string memory memo,
  uint64 ttl,
  uint8 status,
  uint createTime,
  uint updateTime
  ) {
    redpackId = redpacks[id].redpackId;
    sender = redpacks[id].sender;
    receiver = new address[](redpacks[id].receiver.length);
    for (uint i = 0; i < redpacks[id].receiver.length; i++) {
      receiver[i] = redpacks[id].receiver[i];
    }
    totalNumber = redpacks[id].totalNumber;
    leftNumber = redpacks[id].leftNumber;
    totalAmount = redpacks[id].totalAmount;
    leftAmount = redpacks[id].leftAmount;
    memo = redpacks[id].memo;
    ttl = redpacks[id].ttl;
    status = redpacks[id].status;
    createTime = redpacks[id].createTime;
    updateTime = redpacks[id].updateTime;
  }
  
  struct Redpack {
    uint redpackId;
    address sender;
    address[] receiver;
    uint8 totalNumber;
    uint8 leftNumber;
    uint totalAmount; // amount in wei.
    uint leftAmount; // amount in wei.
    string memo;
    uint64 ttl;
    uint8 status;
    uint createTime;
    uint updateTime;
  }
  
  mapping (uint => Redpack) redpacks;
  
  constructor() public {
    owner = msg.sender;
  }
  
  // Standard modifier on methods invokable only by contract owner.
  modifier onlyOwner {
    require (msg.sender == owner, "OnlyOwner methods called by non-owner.");
    _;
  }
  
  // Fallback function deliberately left empty. It's primary use case
  // is to top up the bank roll.
  function () external payable {
  }
  
  function withdrawFunds(address beneficiary, uint withdrawAmount) external onlyOwner {
    require (withdrawAmount <= address(this).balance, "Increase amount larger than balance.");
    sendFunds(beneficiary, withdrawAmount);
  }
  
  // Helper routine to process the payment.
  function sendFunds(address beneficiary, uint amount) private {
    if (beneficiary.send(amount)) {
      emit Payment(beneficiary, amount);
      } else {
        emit FailedPayment(beneficiary, amount);
      }
    }
    
    function sendRedpack(uint8 num, string memo) external payable {
      Redpack storage redpack = redpacks[redpackId_];
      
      require(redpack.sender == address(0), "redpack should be in a 'clean' status");
      require(num >= 1 && num <= 100, "redpack number must >= 1 and <= 100");
      require(bytes(memo).length <= 64, "memo must less than 64 bytes");
      require(msg.value >= MIN_AMOUNT && msg.value <= MAX_AMOUNT, "Redpack quantity must >= 0.01 ether and <= 100 ether");
      
      redpack.redpackId = redpackId_;
      redpack.sender = msg.sender;
      redpack.totalNumber = redpack.leftNumber = num;
      redpack.totalAmount = msg.value;
      redpack.leftAmount = msg.value;
      redpack.memo = memo;
      redpack.ttl = 10 * 60;
      redpack.status = 0;
      redpack.createTime = redpack.updateTime = now;
      
      redpackId_++;
    }
    
    function returnRedpack(uint id) external onlyOwner {
      Redpack storage redpack = redpacks[id];
      require(redpack.sender != address(0) && redpack.status == 0, "redpack status error");
      require(now >= redpack.createTime + redpack.ttl, "redpack not expired");
      
      uint amount = 0;
      if (redpack.leftNumber == redpack.totalNumber) {
        amount = redpack.totalAmount;
        } else {
          amount = redpack.leftAmount - redpack.totalAmount * 2 / 100;
        }
        
        redpack.status = 2;
        redpack.updateTime = now;
        
        if (amount > 0) {
          sendFunds(redpack.sender, amount);
        }
      }
      
      function grabRedpack(uint id, address player, uint amount) external onlyOwner {
        Redpack storage redpack = redpacks[id];
        
        require(redpack.sender != address(0) && redpack.status == 0, "redpack status error");
        require(now <= redpack.createTime + redpack.ttl, "redpack expired");
        require(redpack.leftNumber > 0, "not enough redpack number");
        require(redpack.leftAmount >= amount, "not enough quantity in the redpack");
        require(amount > 0, "invalid quantity");
        
        for (uint i = 0; i < redpack.receiver.length; i++) {
          require(redpack.receiver[i] != player, "player has already grab this redpack");
        }
        
        if (--redpack.leftNumber == 0) {
          redpack.status = 1;
        }
        redpack.leftAmount -= amount;
        redpack.updateTime = now;
        redpack.receiver.push(player);
        
        sendFunds(player, amount);
      }
      
      function kill() external onlyOwner {
        selfdestruct(owner);
      }
    }
    