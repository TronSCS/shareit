pragma solidity ^0.4.25;

import "SafeMath.sol";
import "Retrievable.sol";

contract FunctieB is Retrievable {

    using SafeMath for uint256;

    event Paid(address payee);

    mapping (address => bool) private _payees;

    uint256 private _totalPayees;

    uint256 public price = 1000;

    /**
    * @dev Total number of accounts that paid
    */
    function totalPayees() external view returns (uint256) {
        return _totalPayees;
    }

    /**
    * @dev Returns whether someone has paid
    * @param _who address which needs to be checked for payment
    * @return return the status of payment
    */
    function hasPaid(address _who) external view returns (bool) {
        return _payees[_who];
    }

    /**
    * @dev sets the price one has to pay for access
    * @param _price price of the cost to gain access
    */
    function setPrice(uint256 _price) public onlyOwner {
        require(_price > 0);
        price = _price;
    }

    /**
    * @dev Allows someone to pay for permission to access FunctieC contract
    * @param _payee address that gets access when purchase is succesfull
    */
    function pay(address _payee) external payable {
        require(msg.value >= price, "Amount paid is too low");
        require(!this.hasPaid(_payee), "Already bought access");
        
        if (msg.value > price) {
            uint256 remainder = msg.value.sub(price);
            msg.sender.transfer(remainder);
        }

        _payees[_payee] = true;
        _totalPayees = _totalPayees.add(1);

        emit Paid(_payee);
    }
}