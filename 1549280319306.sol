//KhanhND: Your entry file here! When you run compiled this file, files declare with import keyword is loaded automatically.
//File Mortal.sol must exist in this Project. 

pragma solidity ^0.4.23; 
    contract AAA {

    event Sig(bytes32 sig);
    function withdrawTRX(uint256 amount, bytes sig) external {
        emit Sig(createMessageWithdraw(keccak256(abi.encodePacked(amount))));
    }
    
    function createMessageWithdraw(bytes32 hash) internal view returns (bytes32) {
        return keccak256(abi.encodePacked(msg.sender,1,address(this),hash));
    }
}