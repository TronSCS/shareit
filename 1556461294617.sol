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

    event OwnershipTransferred(address indexed _from, address indexed _to);

    constructor() public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address _newOwner) public onlyOwner {
        newOwner = _newOwner;
    }

    //the reason for this flow is to protect owners from sending ownership to unintended address due to human error
    function acceptOwnership() public {
        require(msg.sender == newOwner);
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
        newOwner = address(0);
    }
}

//**************************************************************************//
//---------------------  TRONTOPIA CONTRACT INTERFACE  ---------------------//
//**************************************************************************//

interface TRONtopiaInterface {
    function transfer(address recipient, uint amount) external returns(bool);
} 
    
//**************************************************************************//
//---------------------  DIV POOL MAIN CODE STARTS HERE --------------------//
//**************************************************************************//

contract TRONtopia_Dividend_Pool is owned{

    /* Public variables of the contract */
    address public topiaTokenContractAddress;


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
    *   This function only called by token contract.
    */
    function requestDividendPayment(uint256 dividendAmount) public returns(bool) {

        require(msg.sender == topiaTokenContractAddress, 'Unauthorised caller');
        //dividendPaidAllTime += dividendAmount; //no safemath used as underflow is impossible, and it saves some energy
        msg.sender.transfer(dividendAmount);

        return true;

    }

    /**
        Just in rare case, owner wants to transfer Tokens from contract to owner address
    */
    function manualWithdrawTokens(uint256 tokenAmount) public onlyOwner returns(string){
        
        // no need for overflow checking as that will be done in transfer function
        TRONtopiaInterface(topiaTokenContractAddress).transfer(msg.sender, tokenAmount);
        
        return "Transaction successful";
    }


    /**
        Function allows owner to upate the Topia contract address
    */
    function updateTopiaTokenContractAddress(address _newAddress) public onlyOwner returns(string){
        
        require(_newAddress != address(0), 'Invalid Address');
        topiaTokenContractAddress = _newAddress;

        return "Topia Token Contract Address Updated";
    }


}