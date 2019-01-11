pragma solidity ^0.5.2;
contract hhi{

    function deposit() public payable {
        require(msg.value>0, 'Send some trx');
        require(msg.value>1e6, 'Send 1 trx');
    }
}