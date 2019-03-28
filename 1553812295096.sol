//KhanhND: Your entry file here! When you run compiled this file, files declare with import keyword is loaded automatically.
//File Mortal.sol must exist in this Project. 

pragma solidity ^0.4.25;
import 'Mortal.sol';

contract Greeter is Mortal  {
    /* Define variable greeting of the type string */
    string greeting;

    /* This runs when the contract is executed */
    constructor(string memory _greeting) public {
        greeting = _greeting;
    }

    /* Main function */
    function greet() public view returns (string memory) {
        return greeting;
    }
