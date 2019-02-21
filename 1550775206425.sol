pragma solidity ^0.4.25;
contract testOutput{
  bytes4 public bytes4Var;
  constructor(bytes4 inp) public{
    bytes4Var=inp;
  }
  function setBytes4(bytes4 inp) public returns(bytes4){
    bytes4Var=inp;
    return inp;
  }
  }