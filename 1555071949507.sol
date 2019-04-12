pragma solidity ^0.4.25;

import "./Ownable.sol";
import "./ERC721.sol";

contract SwordFactory is Ownable, ERC721 {
    event NewSword(uint swordId, string name);

    struct Sword {
        string name;
        uint32 level;
    }

    Sword[] public swords;
    uint constant buyPrice = 1 trx;
    uint constant levelUpPrice = 10 trx;
    uint constant public swordLimit = 1000;
    uint public totalSwordsNum = 0;

    function createSword(string memory _name) public payable {
        require(msg.value >= buyPrice, "not enough TRX.");
        require(totalSwordsNum < swordLimit, "reach the max limit.");

        uint id = swords.push(Sword(_name, 0)) - 1;
        _mint(msg.sender, id);

        totalSwordsNum++;

        emit NewSword(id, _name);
    }

    function levelUp(uint id) public payable returns (bool) {
        require(msg.value >= levelUpPrice, "not enough TRX.");
        require(msg.sender == ownerOf(id), "not your sword.");

        //Warning: This is for demo purpose, DO NOT use this kind of random number in mainnet
        uint randomNumber = uint(keccak256(abi.encodePacked(blockhash(block.number-1)))) % 100 + 1;

        Sword storage sword = swords[id];
        if (sword.level < 5) {
            if (randomNumber < 90) {
                sword.level++;
                return true;
            }
        } else if (sword.level < 10) {
            if (randomNumber < 70) {
                sword.level++;
                return true;
            }
        } else {
            if (randomNumber < 50) {
                sword.level++;
                return true;
            }
        }

        return false;
    }

    function getSword(uint id) public view returns(string memory name, uint32 level) {
        Sword memory sword = swords[id];
        
        return (
            sword.name,
            sword.level
        );
    }
}
