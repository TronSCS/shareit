pragma solidity >=0.4.0 <0.6.0;

/// @title Whitelisting for the cubs airdrop
contract Whitelist {

    // State variables
    address[] public addressList;
	uint public listLength = 0;
	mapping(address => bool) public addressMapping;

	// White list the address of the sender
    function whiteList() public {
		
		require(addressMapping[msg.sender] != true, "Already whitelisted.");
		
		listLength++;
		addressList.push(msg.sender);
		addressMapping[msg.sender] = true;
		
    }

}
