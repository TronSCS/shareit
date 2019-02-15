pragma solidity ^0.4.23;

contract Test {
  uint x;
  function() external payable {
    x = x + 1;
  }
  function get() public view returns (uint) {
    return x;
  }
}

contract Caller {
  function callTest(address testAddress) public {
    testAddress.call("invalid");
  }
}