pragma solidity ^0.5.0;

// safeMath library //
library SafeMath {

    function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
        if (a == 0) {
            return 0;
        }

        c = a * b;
        assert(c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }
    
    function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
        c = a + b;
        assert(c >= a);
        return c;
    }
}
contract TronTopia{
    using SafeMath for uint;
    uint[] indexes;
    uint256[] public multipliersData;
    address public PubKey = TQcggWN1qFW2dU6gAfMGF2TjgKxAbigqW1;
    bytes32 private PrivKey; 
    uint nonce = 0;    
//constructor to pass privkey 
constructor (bytes32 _privKey) internal {
    //PubKey = _pubKey;
    PrivKey = _privKey;
}
//addMultiplier to store multiplier array data in contract
function addMultiplier (uint256[] memory data) public{
  multipliersData = data;
}
//function to get multiplier data and check its correct
function get(uint i) public view returns (uint256) {
        return multipliersData[i];
}
//function to roll dice and win or loose game
function roll(uint _startNumber,uint _endNumber,uint _amount) public returns(uint256) {
         uint range = _endNumber.sub(_startNumber);
         uint winingNumber = random();
         if(winingNumber>=_startNumber && winingNumber<=_endNumber){
             uint256 multiplier = multipliersData[winingNumber];
             return multiplier;
    //         uint256 winStake = multiplier.mul(_amount).div(10000);
    //         return winStake;   
    //     }else {
    //         return 0;
         }
    //         //return range;
}
//function to generate random number
function random() internal returns (uint) {
        uint randomnumber = uint(keccak256(abi.encodePacked(now, msg.sender, nonce))) % 99;
        randomnumber = randomnumber + 1;
        nonce++;
        return randomnumber;
}
}