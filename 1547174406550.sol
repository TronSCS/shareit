pragma solidity ^0.5.2;
contract test{
    function mutilReturn() public view returns(address,string memory,uint256){
        return (
            msg.sender,
            "hi",
            1        );
    }
}
//TSLK1QWK3dKbst4QvEGpv6Nhn3cGUQzoTe