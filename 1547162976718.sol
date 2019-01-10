pragma solidity ^0.4.23;

contract Factory {

    function newWallet() payable public returns (Wallet wallet)
    {
        wallet = new Wallet(msg.sender);
        address(wallet).transfer(msg.value);
    }

}

contract Wallet {
    address public owner;
    
        modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }
    
    function() external payable { }

    constructor(address _owner) payable public {
        owner = _owner;
    }
    
    function _withdraw() public onlyOwner {
        msg.sender.transfer(address(this).balance);
    } 
}