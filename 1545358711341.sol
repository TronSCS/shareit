pragma solidity ^0.4.25;

contract SafeMath {

  function add(uint256[] nums) public pure returns (uint256) {
    uint256 c;
    for(uint i=0;i<nums.length;i++){
        c=c+nums[i];
    }
    return c;
  }

}
