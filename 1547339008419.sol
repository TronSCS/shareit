pragma solidity ^0.4.23;

contract Factory {
    mapping(address=>address) public listWallet;
    function newWallet() payable public returns (address wallet)
    {
        wallet = new Wallet(msg.sender);
        address(wallet).transfer(msg.value);
        listWallet[msg.sender]=address(wallet);
        return address(wallet);
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
    
    function withdraw() public onlyOwner {
        msg.sender.transfer(address(this).balance);
    } 
}