pragma solidity >=0.4.0 <0.6.0;

/// @title Recreating the sync bug on Tron
contract Syncbug {

    // State variables
    uint256 public timestamp;
	uint32 public counter = 0;

	// Counts up the updateCounter and saves the timestamp
    function triggerUpdate() public {
		
		timestamp = now;
		counter++;
		return();
    }

	// Counts up the updateCounter and saves the timestamp
    function triggerUpdate2() public {
		
		timestamp = now;
		counter++;
    }
    
    // Counts up the updateCounter and saves the timestamp
    function triggerUpdate3() public {
		
		timestamp = now;
		counter++;
    }

	// Read timestamp 
	function readTimestamp() public view returns (uint256) {

		return timestamp; 

	}
	
	// Read updateCounter
	function readCounter() public view returns (uint32){
		
    	return counter;
		
	}
	
	// Calc difference
	function calcDiff() public view returns (uint256){
		
		return now-timestamp;
		
	}

}

