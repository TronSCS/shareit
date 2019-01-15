pragma solidity ^0.4.18;
contract CheckContract {
    function meIsContract() public payable returns(bool){
        if(msg.sender==tx.origin){
            return false;
        }
        else
        {
            return true;
        }
    }
    function isContract(address _address) public view returns (bool){
        uint32 size;
        assembly {
            size := extcodesize(_address)
        }
        return (size > 0);
    }
}
contract Existing  {
    
    CheckContract dc;
    
    function Existing(address _t) public {
        dc = CheckContract(_t);
    }
    
    function verifed() public payable returns (bool){
        return dc.meIsContract();
    }

}