pragma solidity ^0.4.0;

contract Statistics {
  
  // 一期骰子游戏结的数据结构体
  struct Bet {
    uint8 id;
    // The number chosen by the player.
    uint8 number;
    // The Bet Result numbers
    uint8 dice;
    // status 1 is opened success, 2 is refund success,3 is refund fail;
    uint8 status;
    //block.timestamp
    uint8 timestamp;
    //modulo = 1 is < module = 2 is >
    uint8 modulo;
  }
  Bet private bett;
  //下注
  function placeBet(uint8 _number, uint8 modulo) external payable {
    bett= Bet(uint8(1), _number, uint8(0), uint8(0), uint8(block.timestamp), modulo);
    
  }
  
  
}
