pragma solidity ^0.4.23;

import "SafeMath.sol";
/**
 * @title Capped token
 * @dev Mintable token with a token cap.
 */
contract TronSlotCoin {
    
    using SafeMath for uint256;
    string public name="TronSlotCoin2";
    string public symbol="TSC2";
    uint8 public decimals=8;
    address public owner;
    uint256 totalSupply = 100000000*10**uint256(decimals);
    
    event Transfer(
        address indexed from,
        address indexed to,
        uint256 value
    );

    mapping (address => uint256) public balances;

    constructor () public {
        owner=msg.sender;
        balances[owner] = totalSupply;

    }

    /**
     * @dev Gets the balance of the specified address.
     * @param who The address to query the balance of.
     * @return An uint256 representing the amount owned by the passed address.
     */
    function balanceOf(address who) public view returns (uint256) {
        return balances[who];
    }

  /**
     * @dev Internal function that mints an amount of the token and assigns it to
     * an account. This encapsulates the modification of balances such that the
     * proper events are emitted.
     * @param account The account that will receive the created tokens.
     * @param value The amount that will be created.
     */
    function mint(address account, uint256 value) public {
        require(account != address(0));
        require(msg.sender == owner);

        transfer(account,value);

    }



    /**
     * @dev Transfer token for a specified address
     * @param to The address to transfer to.
     * @param value The amount to be transferred.
     */
    function transfer(address to, uint256 value) public returns (bool) {
        _transfer(msg.sender, to, value);
        return true;
    }

    
    /**
     * @dev Transfer token for a specified addresses
     * @param from The address to transfer from.
     * @param to The address to transfer to.
     * @param value The amount to be transferred.
     */
    function _transfer(address from, address to, uint256 value) internal {
        require(to != address(0));

        balances[from] = balances[from].sub(value);
        balances[to] = balances[to].add(value);
        emit Transfer(from, to, value);
    }


}
