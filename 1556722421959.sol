pragma solidity ^0.4.25;

contract testArray {
    uint256[] public arr;

  function inPutz(uint256[] iArr) public {

      for(uint i=0;i<5;i++){

          arr[i]= iArr[i];
      }
      
  }
}