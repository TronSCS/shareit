pragma solidity 0.4.25; /*


  _______ _____   ____  _   _ _              _           _____                          _       
 |__   __|  __ \ / __ \| \ | | |            (_)         |  __ \                        | |      
    | |  | |__) | |  | |  \| | |_ ___  _ __  _  __ _    | |__) | __ ___  ___  ___ _ __ | |_ ___ 
    | |  |  _  /| |  | | . ` | __/ _ \| '_ \| |/ _` |   |  ___/ '__/ _ \/ __|/ _ \ '_ \| __/ __|
    | |  | | \ \| |__| | |\  | || (_) | |_) | | (_| |   | |   | | |  __/\__ \  __/ | | | |_\__ \
    |_|  |_|  \_\\____/|_| \_|\__\___/| .__/|_|\__,_|   |_|   |_|  \___||___/\___|_| |_|\__|___/
                                      | |                                                       
                                      |_|                                                       


    ██████╗ ██╗██╗   ██╗██╗██████╗ ███████╗███╗   ██╗██████╗     ██████╗  ██████╗  ██████╗ ██╗     
    ██╔══██╗██║██║   ██║██║██╔══██╗██╔════╝████╗  ██║██╔══██╗    ██╔══██╗██╔═══██╗██╔═══██╗██║     
    ██║  ██║██║██║   ██║██║██║  ██║█████╗  ██╔██╗ ██║██║  ██║    ██████╔╝██║   ██║██║   ██║██║     
    ██║  ██║██║╚██╗ ██╔╝██║██║  ██║██╔══╝  ██║╚██╗██║██║  ██║    ██╔═══╝ ██║   ██║██║   ██║██║     
    ██████╔╝██║ ╚████╔╝ ██║██████╔╝███████╗██║ ╚████║██████╔╝    ██║     ╚██████╔╝╚██████╔╝███████╗
    ╚═════╝ ╚═╝  ╚═══╝  ╚═╝╚═════╝ ╚══════╝╚═╝  ╚═══╝╚═════╝     ╚═╝      ╚═════╝  ╚═════╝ ╚══════╝
                                                                                                


----------------------------------------------------------------------------------------------------

=== MAIN FEATURES ===
    => Fund gets transferred into this contract periodically from games contracts
    => fund will be requested by token contract, while dividend distribution

=== Independant Audit of the code ===
    => https://hacken.io
    => Multiple Freelancers Auditors
    => Community Audit by Bug Bounty program


------------------------------------------------------------------------------------------------------
 Copyright (c) 2019 onwards TRONtopia Inc. ( https://trontopia.co )
 Contract designed by EtherAuthority  ( https://EtherAuthority.io )
------------------------------------------------------------------------------------------------------
*/ 


//*******************************************************************//
//---------------------No SafeMath Library Needed  ------------------//
//*******************************************************************//


//*******************************************************************//
//------------------ Contract to Manage Ownership -------------------//
//*******************************************************************//
    

contract owned {
    address internal owner;
    address internal newOwner;

    /**
        Signer is deligated admin wallet, which can do sub-owner functions.
        Signer calls following four functions:
            => request fund from game contract
    */
    address internal signer;

    event OwnershipTransferred(address indexed _from, address indexed _to);

    constructor() public {
        owner = msg.sender;
        signer = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    modifier onlySigner {
        require(msg.sender == signer);
        _;
    }

    function changeSigner(address _signer) public onlyOwner {
        signer = _signer;
    }

    function transferOwnership(address _newOwner) public onlyOwner {
        newOwner = _newOwner;
    }

    //this flow is to prevent transferring ownership to wrong wallet by mistake
    function acceptOwnership() public {
        require(msg.sender == newOwner);
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
        newOwner = address(0);
    }
}


//**************************************************************************//
//---------------------    GAMES CONTRACT INTERFACE    ---------------------//
//**************************************************************************//

interface InterfaceGAMES {
    function displayAvailableDividend() external returns (bool, uint256);
    function requestDividendPayment(uint256 amount) external returns(bool);
}  

    
//**************************************************************************//
//---------------------  DIV POOL MAIN CODE STARTS HERE --------------------//
//**************************************************************************//

contract TRONtopia_Dividend_Pool is owned{

    /* Public variables of the contract */
    address public topiaTokenContractAddress;

    mapping (address => bool) public whitelistCaller;
    address[] public whitelistCallerArray;
    mapping (address => uint256) internal whitelistCallerArrayIndex;


    /**
        Fallback function. It just accepts incoming TRX
    */
    function () payable external {}


    /**
    *   Function to view available dividend amount
    */
    function displayAvailableDividend() public view returns (bool, uint256){

        //This will return the TRX balance of dividend pool
        uint256 contractBalance = address(this).balance;
        if( contractBalance > 0 ){
            return (true, contractBalance );
        }
        else{
            //If there is zero balance, then also we want to return false and zero value, 
            //because otherwise, token contract will attempt to request payemnt from this contract and it will cost more gas
            return (false, 0);
        }

    }

    

    /**
        This function only called by token contract.
        This will allows TRX will be sent to token contract for dividend distribution
    */
    function requestDividendPayment(uint256 dividendAmount) public returns(bool) {

        require(msg.sender == topiaTokenContractAddress, 'Unauthorised caller');
        //dividendPaidAllTime += dividendAmount; //no safemath used as underflow is impossible, and it saves some energy
        msg.sender.transfer(dividendAmount);

        return true;

    }


    /**
        Function allows owner to upate the Topia contract address
    */
    function updateTopiaTokenContractAddress(address _newAddress) public onlyOwner returns(string){
        
        require(_newAddress != address(0), 'Invalid Address');
        topiaTokenContractAddress = _newAddress;

        return "Topia Token Contract Address Updated";
    }


    /**
        This function will allow signer to request fund from ALL the game contracts
        Game contracts must be whitelisted
    */
    function requestFundFromGameContracts() public onlySigner returns(bool){

        //first finding excesive fund from ALL game contracts
        uint256 totalGameContracts = whitelistCallerArray.length;
        for(uint i=0; i < totalGameContracts; i++){
            (bool status, uint256 amount) = InterfaceGAMES(whitelistCallerArray[i]).displayAvailableDividend();
            if(status){
                //if status is true, which means particular game has positive dividend available
                //we will request that dividend TRX from game contract to this dividend contract
                InterfaceGAMES(whitelistCallerArray[i]).requestDividendPayment(amount);
            }
            //else nothing will happen
        }
    }


    /** 
        * Add whitelist address who can call Mint function. Usually, they are other games contract
    */
    function addWhitelistAddress(address _newAddress) public onlyOwner returns(string){
        
        require(isContract(_newAddress), 'Only Contract Address can be whitelisted');
        require(!whitelistCaller[_newAddress], 'No same Address again');

        whitelistCaller[_newAddress] = true;
        whitelistCallerArray.push(_newAddress);
        whitelistCallerArrayIndex[_newAddress] = whitelistCallerArray.length - 1;

        return "Whitelisting Address added";
    }

    /**
        * To remove any whilisted address
    */
    function removeWhitelistAddress(address _address) public onlyOwner returns(string){
        
        require(_address != address(0), 'Invalid Address');
        require(whitelistCaller[_address], 'This Address does not exist');

        whitelistCaller[_address] = false;
        uint256 arrayIndex = whitelistCallerArrayIndex[_address];
        address lastElement = whitelistCallerArray[whitelistCallerArray.length - 1];
        whitelistCallerArray[arrayIndex] = lastElement;
        whitelistCallerArrayIndex[lastElement] = arrayIndex;
        whitelistCallerArray.length--;

        return "Whitelisting Address removed";
    }

    /**
        * Function to check if given address is contract address or not.
        * We are aware that this function will not work if calls made from constructor.
        * But we believe that is fine in our use case because the function using this function is called by owner only..
    */
    function isContract(address _address) internal view returns (bool){
        uint32 size;
        assembly {
            size := extcodesize(_address)
        }
        return (size > 0);
    }


}