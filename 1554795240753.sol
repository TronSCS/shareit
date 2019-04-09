/*! tronbuilding.tron.sol | (c) 2019 Develop by BelovITLab LLC (smartcontract.ru), author @stupidlovejoy | License: MIT */

pragma solidity 0.4.25;

contract TronBuilding {
    struct Build {
        uint price;
        uint payout_per_hour;
        uint life_days;
    }

    struct Player {
        uint balance;
        uint balance_withdrawable;
        uint last_payout;
        uint withdraw;
        bytes32[] builds;
        uint[] builds_time;
    }

    address public owner;
    
    // !!! Для теста рейтинг увеличен (при деплои в основную сеть заменить значение на 25) !!!
    uint constant RATE = 100000;

    mapping(bytes32 => Build) public builds;
    mapping(address => Player) public players;

    event Donate(address indexed addr, uint amount);
    event Deposit(address indexed addr, uint value, uint amount);
    event BuyBuild(address indexed addr, bytes32 name);
    event Withdraw(address indexed addr, uint value, uint amount);

    modifier onlyOwner() {
        require(msg.sender == owner, "Access denied");
        _;
    }

    constructor() public {
        owner = msg.sender;

        builds['store'] = Build({price: 3850 trx, payout_per_hour: 5 trx, life_days: 86});
        builds['pizzeria'] = Build({price: 12500 trx, payout_per_hour: 17 trx, life_days: 88});
        builds['hotel'] = Build({price: 50400 trx, payout_per_hour: 70 trx, life_days: 90});
        builds['restaurant'] = Build({price: 180000 trx, payout_per_hour: 255 trx, life_days: 88});
        builds['casino'] = Build({price: 495000 trx, payout_per_hour: 715 trx, life_days: 86});
        builds['bank'] = Build({price: 980000 trx, payout_per_hour: 1450 trx, life_days: 84});
    }

    function _payout(address addr) private {
        uint payout = payoutOf(addr);

        if(payout > 0) {
            players[addr].balance += payout / 2;
            players[addr].balance_withdrawable += payout / 2;
            players[addr].last_payout = block.timestamp;
        }
    }

    function _deposit(address addr, uint value) private {
        uint amount = value * RATE;

        players[addr].balance += amount;

        emit Deposit(addr, value, amount);
    }
    
    function _buyBuild(address addr, bytes32 name) private {
        require(builds[name].price > 0, "Build not found");

        Player storage player = players[addr];

        _payout(addr);
        
        require(player.balance >= builds[name].price, "Insufficient funds");

        player.balance -= builds[name].price;
        players[owner].balance_withdrawable += builds[name].price / 10;

        player.builds.push(name);
        player.builds_time.push(block.timestamp);

        emit BuyBuild(addr, name);
    }

    function() payable external {
        revert();
    }

    function donate() payable external {
        emit Donate(msg.sender, msg.value);
    }

    function deposit() payable external {
        _deposit(msg.sender, msg.value);
    }

    function buyBuild(bytes32 name) external {
        _buyBuild(msg.sender, name);
    }

    function buyBuilds(bytes32[] names) external {
        require(names.length > 0, "Empty names");

        for(uint i = 0; i < names.length; i++) {
            _buyBuild(msg.sender, names[i]);
        }
    }

    function depositAndBuyBuild(bytes32 name) payable external {
        _deposit(msg.sender, msg.value);
        _buyBuild(msg.sender, name);
    }
    
    function depositAndBuyBuilds(bytes32[] names) payable external {
        require(names.length > 0, "Empty names");

        _deposit(msg.sender, msg.value);

        for(uint i = 0; i < names.length; i++) {
            _buyBuild(msg.sender, names[i]);
        }
    }

    function withdraw(uint value) external {
        require(value > 0, "Small value");

        Player storage player = players[msg.sender];

        _payout(msg.sender);

        require(player.balance_withdrawable >= value, "Insufficient funds");

        player.balance_withdrawable -= value;
        player.withdraw += value;
        
        msg.sender.transfer(value / RATE);

        emit Withdraw(msg.sender, value / RATE, value);
    }

    // !!! Владелец может добавлять/менять здания что снижает ДОВЕРИЕ к игре (при ненадобности функции вырезать из кода) !!!
    function setBuild(bytes32 name, uint price, uint payout_per_hour, uint life_days) onlyOwner external {
        builds[name] = Build({price: price, payout_per_hour: payout_per_hour, life_days: life_days});
    }

    // !!! Владелец может удалить контракт и забрать с него все бабки что снижает ДОВЕРИЕ к игре (при ненадобности функции вырезать из кода) !!!
    function destruct() onlyOwner external {
        selfdestruct(owner);
    }

    function payoutOf(address addr) view public returns(uint value) {
        Player storage player = players[addr];

        for(uint i = 0; i < player.builds.length; i++) {
            uint time_end = player.builds_time[i] + builds[player.builds[i]].life_days * 86400;
            uint from = player.last_payout > player.builds_time[i] ? player.last_payout : player.builds_time[i];
            uint to = block.timestamp > time_end ? time_end : block.timestamp;

            if(from < to) {
                value += ((to - from) / 3600) * builds[player.builds[i]].payout_per_hour;
            }
        }

        return value;
    }
    
    function balanceOf(address addr) view external returns(uint balance, uint balance_withdrawable) {
        uint payout = payoutOf(addr);

        return (players[addr].balance + payout / 2, players[addr].balance_withdrawable + payout / 2);
    }
}