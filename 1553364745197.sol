pragma solidity >=0.4.0 <0.6.0;

/// @title Recreating the now sync bug on Tron
contract NowSync {

  // State variables
  uint256 public timestamp = now;

	// Counts up the updateCounter and saves the timestamp
	function triggerUpdate() public {
	
			timestamp = now;
  
	}

	// Calc difference
	function showValues() public view returns (uint256, uint256){
		
		return (now, timestamp);
		
	}

}

