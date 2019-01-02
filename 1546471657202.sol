pragma solidity 0.4.23;

contract CryptidCreation {
    
    uint256 rnd_num_FACTOR = 1157920892373161954235709850086879078532699846656405640394575840079131296399;
    
    constructor() public {
        
    }
    
    function get_rnd_num() public view returns(uint number) {
        uint256 _hash =  uint256(keccak256(now));
        return uint256(uint256(_hash) / rnd_num_FACTOR) + 1;
    }

}