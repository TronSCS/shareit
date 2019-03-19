pragma solidity ^0.4.25;

interface tokenRecipient { 
    function receiveApproval(address _from, uint256 _value, address _token, bytes  _extraData) external; 
}

library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        assert(c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a / b;
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}

library Helper {
    
    function bytes32ToString (bytes32 data)
        internal
        pure
        returns (string) 
    {
        bytes memory bytesString = new bytes(32);
        for (uint j=0; j<32; j++) {
            byte char = byte(bytes32(uint(data) * 2 ** (8 * j)));
            if (char != 0) {
                bytesString[j] = char;
            }
        }
        return string(bytesString);
    }
    
    function uintToBytes32(uint256 n)
        internal
        pure
        returns (bytes32) 
    {
        return bytes32(n);
    }
    
    function bytes32ToUint(bytes32 n) 
        internal
        pure
        returns (uint256) 
    {
        return uint256(n);
    }
    
    function stringToBytes32(string memory source) 
        internal
        pure
        returns (bytes32 result) 
    {
        bytes memory tempEmptyStringTest = bytes(source);
        if (tempEmptyStringTest.length == 0) {
            return 0x0;
        }

        assembly {
            result := mload(add(source, 32))
        }
    }
    
    function isVaidUsername(string _username)
        internal
        pure
        returns(bool)
    {
        uint256 len = bytes(_username).length;
        // username max length 6 - 32
        if ((len < 6) || (len > 32)) return false;
        // last character not space
        if (bytes(_username)[len-1] == 32) return false;
        // first character not zero
        return uint256(bytes(_username)[0]) != 48;
    }
    
    function stringToNumber(string memory source) 
        internal
        pure
        returns (uint256)
    {
        return bytes32ToUint(stringToBytes32(source));
    }
    
    function numberToString(uint256 _uint) 
        internal
        pure
        returns (string)
    {
        return bytes32ToString(uintToBytes32(_uint));
    }
}

contract GakexMain {
    using SafeMath for *;
    
    // check is admin
    modifier onlyAdmin(){
        require(msg.sender == owner, "admin required");
        _;
    }
    
    modifier onlyUserAddress () {
        require(msg.sender == userAddress, "user address required");
        _;
    }
    
    modifier onlyNetwork () {
        require(msg.sender == owner || msg.sender == userAddress || msg.sender == exchangeAddress, "network required");
        _;
    }
    
    // This creates an array with all balances
    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;
    mapping (address => bool) public frozenAccount;
    mapping (address => uint256) public holdBalance;

    // This generates a public event on the blockchain that will notify clients
    event Transfer(address indexed from, address indexed to, uint256 value);
    
    // This generates a public event on the blockchain that will notify clients
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
    
    uint256 public TRON_PRICE_USD;
    uint256 public TOKEN_PRICE_USD;
    uint256 public totalBalance;
    uint256 public totalHold;
    uint256 public totalSupply;
    string public name;
    string public symbol;
    uint32 public decimals;
    // NETWORK ADDRESS
    address private owner;
    address private userAddress;
    address private exchangeAddress;
    
    constructor ()
    public
    {
        owner = msg.sender;
        symbol = "GEX";
        name = "GAKEX";
        decimals = 6;
        totalSupply = 1000000000 * 10**6; // 100,000,000 GEX
        totalBalance = 0;
        totalHold = 0;
        TRON_PRICE_USD = 0.021989 * 10**6;  // $0.021989
        TOKEN_PRICE_USD = 0.01 * 10**6;     // $0.01
        // TOKEN_PRICE_MIN = 0.2 * 10**6;
        // TOKEN_PRICE_MAX = 50 * 10**6;
        // TOKEN_PRICE_TRX = (TOKEN_PRICE_MIN / TRON_PRICE_USD) + ((TOKEN_PRICE_MAX / TRON_PRICE_USD) * (totalHold / totalSupply));
        // TOKEN_PRICE_USD = TOKEN_PRICE_TRX * TRON_PRICE_USD;
    }
    
    function _transfer(address _from, address _to, uint _value) internal {
        // Prevent transfer to 0x0 address. Use burn() instead
        require(_to != address(0x0));
        // Check if the sender has enough
        require(balanceOf[_from] >= _value);
        // Check for overflows
        require(balanceOf[_to] + _value >= balanceOf[_to]);
        // Save this for an assertion in the future
        uint previousBalances = balanceOf[_from] + balanceOf[_to];
        // Subtract from the sender
        balanceOf[_from] -= _value;
        // Add the same to the recipient
        balanceOf[_to] += _value;
        emit Transfer(_from, _to, _value);
        // Asserts are used to use static analysis to find bugs in your code. They should never fail
        assert(balanceOf[_from] + balanceOf[_to] == previousBalances);
    }

    /**
     * Transfer tokens
     *
     * Send `_value` tokens to `_to` from your account
     *
     * @param _to The address of the recipient
     * @param _value the amount to send
     */
    function transfer(address _to, uint256 _value) public returns (bool success) {
        require(!frozenAccount[msg.sender]);
        require(!frozenAccount[_to]);
        require(_value <= getAvaiableBalance(msg.sender));                 // Check avaiableBalance
        _transfer(msg.sender, _to, _value);
        return true;
    }

    /**
     * Transfer tokens from other address
     *
     * Send `_value` tokens to `_to` on behalf of `_from`
     *
     * @param _from The address of the sender
     * @param _to The address of the recipient
     * @param _value the amount to send
     */
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(_value <= allowance[_from][msg.sender]);     // Check allowance
        require(_value <= getAvaiableBalance(_from));                 // Check avaiableBalance
        allowance[_from][msg.sender] -= _value;
        _transfer(_from, _to, _value);
        return true;
    }

    /**
     * Set allowance for other address
     *
     * Allows `_spender` to spend no more than `_value` tokens on your behalf
     *
     * @param _spender The address authorized to spend
     * @param _value the max amount they can spend
     */
    function approve(address _spender, uint256 _value) public
        returns (bool success) {
        allowance[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    /**
     * Set allowance for other address and notify
     *
     * Allows `_spender` to spend no more than `_value` tokens on your behalf, and then ping the contract about it
     *
     * @param _spender The address authorized to spend
     * @param _value the max amount they can spend
     * @param _extraData some extra information to send to the approved contract
     */
    function approveAndCall(address _spender, uint256 _value, bytes memory _extraData)
        public
        returns (bool success) {
        tokenRecipient spender = tokenRecipient(_spender);
        if (approve(_spender, _value)) {
            spender.receiveApproval(msg.sender, _value, address(this), _extraData);
            return true;
        }
    }
    
    function freezeAccount(address target, bool freeze) public onlyAdmin {
        frozenAccount[target] = freeze;
    }
    
    function getAvaiableBalance (address _address) public view returns(uint256) {
        return balanceOf[_address] - holdBalance[_address];
    }
    
    function updateNetwork (address _userAddress, address _exchangeAddress) public onlyAdmin {
        userAddress = _userAddress;
        exchangeAddress = _exchangeAddress;
    }
    
    function buyToken () public payable returns(bool){
        uint256 usd = msg.value.mul(TRON_PRICE_USD);
        uint256 gex = usd.div(TOKEN_PRICE_USD);
        balanceOf[msg.sender] += gex;
        totalBalance += gex;
        return true;
    }
    
    function addBalance(address _address, uint256 _value) 
        public 
        onlyNetwork 
    {
        balanceOf[_address] += _value;
        // update total balance
        totalBalance += _value;
    }
    
    function subtractBalance(address _address, uint256 _value) 
        public 
        onlyNetwork 
    {
        balanceOf[_address] += _value;
        // update total balance
        totalBalance -= _value;
    }
    
    function holdBalance (address _target, uint256 _value)
        public 
        onlyAdmin 
    {
        require(balanceOf[_target] >= _value);
        holdBalance[_target] = _value;
        // update hold balance
        totalHold += _value;
    }
    
    function unHoldBalance(address _target, uint256 _value)
        public
        onlyAdmin 
    {
        require(holdBalance[_target] >= _value);
        holdBalance[_target] -= _value;
        // update hold balance
        totalHold -= _value;
    }
    
    function fromTRX (uint256 _value)
        public
        view
        returns(uint256)
    {
        uint256 usd = _value.mul(TRON_PRICE_USD);
        return usd.div(TOKEN_PRICE_USD);
    }
    
    function toTRX (uint256 _value)
        public
        view
        returns(uint256)
    {
        uint256 usd = _value.mul(TOKEN_PRICE_USD);
        return usd.div(TRON_PRICE_USD);
    }
    
    function updateGEX (uint256 _value)
        public
        onlyAdmin
    {
        TOKEN_PRICE_USD = _value;
    }
    
    function updateTRX (uint256 _value)
        public
        onlyAdmin
    {
        TRON_PRICE_USD = _value;
    }
}

contract GakexUser {
    using SafeMath for *;
    
    GakexMain mainContract;
    
    // check is not registered
    modifier notRegistered(){
        require(!isUser[msg.sender], "not registered");
        _;
    }
    
    // check is admin
    modifier onlyAdmin(){
        require(msg.sender == owner, "admin required");
        _;
    }
    
    // check is admin
    modifier onlyExchangeAddress(){
        require(msg.sender == owner, "admin required");
        _;
    }
    
    struct User{
        uint256 time;
        uint256 id;
        uint256 username;
        address ref;
        uint256 countMyRef;
        address[] myRef;
        uint256 totalDirectCommission;
        uint256 countDirectHistory;
        uint256 totalOrderAmount; // total GAKEX ordered
        uint256 totalCountWin;
        uint256 totalAmountWin;
        uint256 totalCountLose;
        uint256 totalAmountLose;
    }
    
    mapping (address => User) public user;
    mapping (address => bool) public isUser;
    mapping (uint256 => address) public usernameAddress;
    mapping (uint256 => address) public userIdAddress;
    mapping (address => address) public refParent;
    
    uint256 public totalUser;
    address private owner;
    address private exchangeAddress;
    address private mainAddress;
    
    constructor (address _mainAddress)
    public
    {
        owner = msg.sender;
        totalUser = 1;
        
        user[owner].id = totalUser;
        uint256 usernameUint = Helper.stringToNumber('GAKEX');
        user[owner].username = usernameUint;
        isUser[owner] = true;
        usernameAddress[usernameUint] = owner;
        userIdAddress[totalUser] = owner;
        // init main contract
        mainAddress = _mainAddress;
        mainContract = GakexMain(mainAddress);
    }
    
    // ----------------------------------- //
    // --------- SET FUNCTION ------------ //
    // ----------------------------------- //
    
    // SIGN UP FUNCTION
    function signUp (string _username,address _ref) 
        public
        notRegistered() // check this address is not registered
    {
        address sender = msg.sender;
        require(Helper.isVaidUsername(_username), 'can not use this username');
        uint256 username = Helper.stringToNumber(_username);
        require(usernameAddress[username] == 0x0, "username already exist");
        totalUser++;
        usernameAddress[username] = sender;
        userIdAddress[totalUser] = sender;
        
        // direct ref
        address ref = isUser[_ref] ? _ref : owner;
        
        // add to database
        isUser[sender] = true;
        user[sender].time = block.timestamp;
        user[sender].id = totalUser;
        user[sender].username = username;
        user[sender].ref = ref;
        user[sender].countMyRef = 0;
        user[sender].totalCountWin = 0;
        user[sender].totalAmountWin = 0;
        user[sender].totalCountLose = 0;
        user[sender].totalAmountLose = 0;
        
        // add new ref for parent user
        user[ref].myRef.push(sender);
        user[ref].countMyRef++;
        refParent[sender] = _ref;
    }
    
    function updateWin (address _address, uint256 _amount) 
        public
        onlyExchangeAddress
    {
        user[_address].totalCountWin++;
        user[_address].totalAmountWin += _amount;
    }
    
    function updateLose (address _address, uint256 _amount)
        public
        onlyExchangeAddress
    {
        user[_address].totalCountLose++;
        user[_address].totalAmountLose += _amount;
    }
    
    function updateNetwork(address _exchangeAddress, address _mainAddress) public onlyAdmin {
        exchangeAddress = _exchangeAddress;
        mainAddress = _mainAddress;
    }
    
    // ----------------------------------- //
    // --------- GET FUNCTION ------------ //
    // ----------------------------------- //

    function getLevel (address _child, address _parent)
        public
        view
        returns(uint8)
    {
        // Lv0
        require(address(refParent[_child]) != address(0x0), "wrong address");
        
        uint8 result = 1;
        address temp = _child;
        while(refParent[temp] != _parent) {
            temp = refParent[temp];
            result++;
            
            if(temp == 0x0) return 0;
        }
    
        return result;
    }
    
    function getUserInfo (address _address)
        public
        view
        returns (uint256,string,address,uint256,address[])
    {
        return (
            user[_address].id,
            Helper.numberToString(user[_address].username),
            user[_address].ref,
            user[_address].countMyRef,
            user[_address].myRef
        );
    }
    
    function getAddressByUsername (string _username)
        public
        view
        returns (address)
    {
        return usernameAddress[Helper.stringToNumber(_username)];
    }
    
    function getAddressByUserId (uint256 _id)
        public
        view
        returns (address)
    {
        return userIdAddress[_id];   
    }
}

contract GakexExchange {
    using SafeMath for *;
    
    GakexMain mainContract;
    GakexUser userContract;
    
    modifier onlyAdmin(){
        require(msg.sender == owner, "admin required");
        _;
    }
    
    // EVENT
    event NewOrder(uint256 indexed _marketID, address indexed _from, bool _status, uint256 _amount, bool payWith);
    event OpenMarket(uint256 indexed _marketID, uint256 _price);
    event EndMarket(uint256 indexed _marketID, uint256 _price);
    event NewHistory(uint256 indexed _marketID, address indexed _address, uint256 _received, bool payWith);
    
    // 0 TRON
    // 1 BTC
    // 2 ETH
    
    struct MarketStatistic {
        uint256 countOrder;
        uint256 upTotal;
        uint256 downTotal;
        uint256 upCount;
        uint256 downCount;
    }
    
    struct MarketStruct {
        uint256 name;
        bool isOpen;
        uint256 countRound;
        uint256 startPrice;
        uint256 endPrice;
        uint256 timeOpen;
        uint256 timeEnd;
    }
    
    struct MarketOrder {
        address user;
        bool payWith;   // true = TRX, false = GAKEX
        bool status;
        uint256 amount;
    }
    
    struct OrderHistory {
        uint256 time;
        uint256 price;
        bool status;    // true = up , false = down
        uint256 amount;
        uint256 received;
        bool payWith;   // true = TRX, false = GAKEX
        bool win;       // true = win, false = lose
    }
    
    struct Statistic {
        uint256 totalOrder;         // total order
        uint256 totalAmountOrder;   // total usd ordered
        uint256 totalWin;           // total win
        uint256 totalAmountWin;     // total usd win
        uint256 totalLose;          // total lose
        uint256 totalAmountLose;    // total usd lose
        uint256 totalTokenBonus;    // total GEX bonus when make order
    }
    
    MarketStatistic[] private marketStatistic;
    MarketStruct[] public markets;
    mapping (uint256 => mapping(uint256 => MarketOrder)) public marketOrders;
    mapping (address => mapping(uint256 => OrderHistory)) public orderHistory;
    mapping (address => uint256) public countOrderHistory;
    mapping (address => Statistic) public statistic;
    mapping (uint256 => mapping(uint256 => mapping(uint256 => MarketOrder))) public pendingOrders;
    mapping (uint256 => mapping(uint256 => uint256)) public countPendingOrder;
    
    uint256 private WIN_PERCENT;                 // amount received when WIN
    uint256 private MIN_ORDER_TRX;               // min order with TRX
    uint256 private MIN_ORDER_GAKEX;             // min order with GEX
    uint256 private ORDER_BONUS;                 // bonus GEX for anyone make order
    uint256 private ROUND_TIME;                  // time of a round
    uint256 private countMarket = 0;             // number market
    uint256 private openKey;                     // key to request market info
    // NETWORK ADDRESS
    address private owner;
    address private mainAddress;
    address private userAddress;
    
    constructor (address _mainAddress, address _userAddress, uint256 _k)
    public
    {
        owner = msg.sender;
        mainAddress = _mainAddress;
        userAddress = _userAddress;
        mainContract = GakexMain(mainAddress);
        userContract = GakexUser(userAddress);
        // init varialbes
        WIN_PERCENT = 0.95 * (10**6);                                                       // 95%
        MIN_ORDER_TRX = ((0.5*10**6).div(mainContract.TRON_PRICE_USD())) * 10**6;           // $0.5
        MIN_ORDER_GAKEX = ((0.5*10**6).div(mainContract.TOKEN_PRICE_USD())) * 10**6;        // $0.5
        ORDER_BONUS = 0.01*10**6;                                                           // 1%
        ROUND_TIME = 50;                                                                    // 60 second = 1 minute
        openKey = _k;
    }
    
    function setNumber (uint256 _number) 
        public
        onlyAdmin
        returns (bool) 
    {
        openKey = _number;
        return true;
    }
    
    function getMarket(uint256 _id, uint256 _k) 
        public
        constant
        returns(uint256,uint256,uint256,uint256,uint256)
    {
        require(_k == openKey, "require");
        require(_id < countMarket, "market not exist");
        return(marketStatistic[_id].countOrder,marketStatistic[_id].upTotal,marketStatistic[_id].downTotal,marketStatistic[_id].upCount,marketStatistic[_id].downCount);
    }
    
    function resetMarket (uint256 _marketID)
        private
        onlyAdmin()
    {
        marketStatistic[_marketID].countOrder = 0;
        marketStatistic[_marketID].upCount = 0;
        marketStatistic[_marketID].downCount = 0;
        marketStatistic[_marketID].upTotal = 0;
        marketStatistic[_marketID].downTotal = 0;
        
        markets[_marketID].startPrice = 0;
        markets[_marketID].endPrice = 0;
    }
    
    function addMarket (string _name)
        public
        onlyAdmin()
        returns (bool)
    {
        markets[countMarket].name = Helper.stringToNumber(_name);
        markets[countMarket].isOpen = false;
        markets[countMarket].countRound = 0;
        resetMarket(countMarket);
        countPendingOrder[countMarket][0] = 0;
        countMarket++;
        return true;
    }
    
    function openMarket (uint256 _id, uint256 _price)
        public
        onlyAdmin()
        returns (bool)
    {
        require(_id < countMarket, "id not found");
        require(markets[_id].isOpen == false, "market opened");
        
        markets[_id].isOpen = true;
        resetMarket(_id);
        markets[_id].startPrice = _price;
        markets[_id].timeOpen = block.timestamp;
        markets[_id].timeEnd = block.timestamp + ROUND_TIME;
        markets[_id].countRound++;
        
        // order for pending order
        if(countPendingOrder[_id][markets[_id].countRound] > 0) {
            uint256 i;
            for(i = 0;i < countPendingOrder[_id][markets[_id].countRound]; i++) {
                uint256 amountUSD;
                if(pendingOrders[_id][markets[_id].countRound][i].payWith == true) {
                    marketOrders[_id][marketStatistic[_id].countOrder].amount = pendingOrders[_id][markets[_id].countRound][i].amount;
                    amountUSD = pendingOrders[_id][markets[_id].countRound][i].amount.mul(mainContract.TRON_PRICE_USD()); // convert TRX to USD
                    if(pendingOrders[_id][markets[_id].countRound][i].status == true)
                        marketStatistic[_id].upTotal += amountUSD;
                    else
                        marketStatistic[_id].downTotal += amountUSD;
                } else {
                    marketOrders[_id][marketStatistic[_id].countOrder].amount = pendingOrders[_id][markets[_id].countRound][i].amount;
                    amountUSD = pendingOrders[_id][markets[_id].countRound][i].amount.mul(mainContract.TOKEN_PRICE_USD());                                       // convert GEX to USD
                    if(pendingOrders[_id][markets[_id].countRound][i].status == true)
                        marketStatistic[_id].upTotal += amountUSD;
                    else
                        marketStatistic[_id].downTotal += amountUSD;
                }
                
                marketOrders[_id][markets[_id].countRound].user = pendingOrders[_id][markets[_id].countRound][i].user;
                marketOrders[_id][markets[_id].countRound].status = pendingOrders[_id][markets[_id].countRound][i].status;
                marketOrders[_id][markets[_id].countRound].payWith = pendingOrders[_id][markets[_id].countRound][i].payWith;
                
                markets[_id].countRound++;
                
                if(pendingOrders[_id][markets[_id].countRound][i].status == true)
                    marketStatistic[_id].upCount++;
                else
                    marketStatistic[_id].downCount++;
                
                emit NewOrder(_id, pendingOrders[_id][markets[_id].countRound][i].user, pendingOrders[_id][markets[_id].countRound][i].status, pendingOrders[_id][markets[_id].countRound][i].amount, pendingOrders[_id][markets[_id].countRound][i].payWith);
            }
        }
        
        emit OpenMarket(_id, _price);
        return true;
    }
    
    // true = up, false = down
    function endMarket (uint256 _id, uint256 _price)
        public
        onlyAdmin()
        returns (bool)
    {
        require(_id < countMarket, "id not found");
        require(markets[_id].isOpen == true, "market ended");   
        // result
        bool result = _price > markets[_id].startPrice;
        
        for(uint i = 0;i < marketStatistic[_id].countOrder; i++) {
            
            uint256 plusAmount = 0;
            uint256 amountUSD = 0;
            
            // WIN 
            if(marketOrders[_id][i].status == result) {
                // transfer amount for winner
                plusAmount =  (marketOrders[_id][i].amount * WIN_PERCENT).div(10**6);
                if(marketOrders[_id][i].payWith == true) { // true = TRX, false = GEX
                    marketOrders[_id][i].user.transfer(marketOrders[_id][i].amount.add(plusAmount)); // plus root + income because subtract root from order function
                    amountUSD = (plusAmount.mul(mainContract.TRON_PRICE_USD())).div(10**6);
                } else {
                    mainContract.addBalance(marketOrders[_id][i].user,marketOrders[_id][i].amount.add(plusAmount)); // plus root + income because subtract root from order function
                    amountUSD = (plusAmount.mul(mainContract.TOKEN_PRICE_USD())).div(10**6);
                }
                // save statistic
                statistic[marketOrders[_id][i].user].totalWin++;
                statistic[marketOrders[_id][i].user].totalAmountWin += amountUSD;
                // save history
                orderHistory[marketOrders[_id][i].user][countOrderHistory[marketOrders[_id][i].user]] = OrderHistory(
                    block.timestamp,
                    _price,
                    marketOrders[_id][i].status,
                    marketOrders[_id][i].amount,
                    plusAmount,
                    marketOrders[_id][i].payWith,
                    true // true = win, false = lose
                );
            // LOSE
            } else {
                // save history
                orderHistory[marketOrders[_id][i].user][countOrderHistory[marketOrders[_id][i].user]] = OrderHistory(
                    block.timestamp,
                    _price,
                    marketOrders[_id][i].status,
                    marketOrders[_id][i].amount,
                    0,
                    marketOrders[_id][i].payWith,
                    false //true = win, false = lose
                );
                // save statistic
                statistic[marketOrders[_id][i].user].totalLose++;
                if(marketOrders[_id][i].payWith == true) { // true = TRX, false = GEX
                    statistic[marketOrders[_id][i].user].totalAmountLose += marketOrders[_id][i].amount.mul(mainContract.TRON_PRICE_USD()).div(10**6);
                } else {
                    statistic[marketOrders[_id][i].user].totalAmountLose += marketOrders[_id][i].amount.mul(mainContract.TOKEN_PRICE_USD()).div(10**6);
                }
            }
            
            countOrderHistory[marketOrders[_id][i].user]++;
            
            emit NewHistory(_id,marketOrders[_id][i].user,plusAmount,marketOrders[_id][i].payWith);
        }
        
        resetMarket(_id);
        markets[_id].isOpen = false;
        markets[_id].endPrice = _price;
        
        emit EndMarket(_id, _price);
        return true;
    }
    
    // MAX 20 ORDERS
    // function preOrder(uint256 _marketID,bool _payWith,uint8[] _round, bool[] _status, uint256[] _amount)
    //     public
    //     payable
    // {
    //     // check market id
    //     require(_marketID < countMarket, "market id not found");
    //     // check round avaiable
    //     uint8 i = 0;
    //     for(i = 0; i < _round.length; i++) {
    //         require(_round[i] > countMarketRound[_marketID], "pre order round less current round");
    //     }
    //     // check balance
    //     uint256 totalAmount = 0;
    //     for(i = 0; i < _amount.length; i++) {
    //         totalAmount += _amount[i];
    //     }
    //     if(_payWith == true) {  // true = TRX, 
    //         require(msg.value >= totalAmount, "not enough balance");
    //     } else {                // false = GEX
    //         require(mainContract.getAvaiableBalance(msg.sender) >= totalAmount, "not enough balance");
    //     }
        
    //     // subtract balance if pay with GEX
    //     if(_payWith == false) { // false = GEX 
    //         mainContract.subtractBalance(msg.sender, totalAmount);
    //     }
        
    //     // bonus token for sender
    //     uint256 amountUSD;
    //     if(_payWith == true) // true = trx
    //         amountUSD = totalAmount.mul(mainContract.TRON_PRICE_USD()).div(10**6);
    //     else
    //         amountUSD = totalAmount.mul(mainContract.TOKEN_PRICE_USD()).div(10**6);
    //     uint256 bonusToken = amountUSD.mul(ORDER_BONUS).div(mainContract.TOKEN_PRICE_USD());
    //     mainContract.addBalance(msg.sender, bonusToken);
        
    //     // save statistic and emit event
    //     statistic[msg.sender].totalOrder += _round.length;
    //     statistic[msg.sender].totalAmountOrder += amountUSD;
    //     statistic[msg.sender].totalTokenBonus += bonusToken;
            
    //     // save to pre order
    //     for(i = 0; i < _round.length; i++) {
    //         pendingOrders[_marketID][_round[i]][countPendingOrder[_marketID][_round[i]]] = MarketOrder(
    //             msg.sender,
    //             _payWith,
    //             _status[i],
    //             _amount[i]
    //         );
    //         countPendingOrder[_marketID][_round[i]]++;
    //     }
    // }
    
    // Helper function
    function addBonus (address _address, uint256 _amountUSD) private returns(uint256) {
        uint256 bonusToken = _amountUSD.mul(ORDER_BONUS).div(mainContract.TOKEN_PRICE_USD());
        mainContract.addBalance(_address, bonusToken);
        return bonusToken;
    }
    
    // _status: true = up , false = down
    // _payWith: true = TRX, false = GAKEX
    function orderTrx (uint256 _marketID, bool _status)
        public
        payable
        returns (bool)
    {
        uint256 amountUSD;
        // check market id
        require(_marketID < countMarket, "market id not found");
        // check is open
        require(markets[_marketID].isOpen == true, "market is not open");
        // check time's up
        require(block.timestamp < markets[_marketID].timeEnd, "market is ended");
        // check MIN_ORDER
        require(msg.value > MIN_ORDER_TRX, "not enough balance");
        // convert TRX to USD
        amountUSD = msg.value.mul(mainContract.TRON_PRICE_USD()).div(10**6);
        if(_status == true)
            marketStatistic[_marketID].upTotal += amountUSD;
        else
            marketStatistic[_marketID].downTotal += amountUSD;
        
        marketOrders[_marketID][marketStatistic[_marketID].countOrder].amount = msg.value;
        marketOrders[_marketID][marketStatistic[_marketID].countOrder].user = msg.sender;
        marketOrders[_marketID][marketStatistic[_marketID].countOrder].status = _status;
        marketOrders[_marketID][marketStatistic[_marketID].countOrder].payWith = true; // payWith = true = TRX
        
       marketStatistic[_marketID].countOrder++;
        
        if(_status == true)
            marketStatistic[_marketID].upCount++;
        else
            marketStatistic[_marketID].downCount++;
        
        // save statistic and emit event
        statistic[msg.sender].totalOrder++;
        statistic[msg.sender].totalAmountOrder += amountUSD;
        // bonus token for sender
        statistic[msg.sender].totalTokenBonus += addBonus(msg.sender,amountUSD);
        
        emit NewOrder(_marketID, msg.sender, _status, msg.value, true);
        return true;
    }
    
    function orderGex (uint256 _marketID, bool _status, uint256 _amountToken)
        public
        payable
        returns (bool)
    {
        uint256 amountUSD;
        // check market id
        require(_marketID < countMarket, "market id not found");
        // check is open
        require(markets[_marketID].isOpen == true, "market is not open");
        // check time's up
        require(block.timestamp < markets[_marketID].timeEnd, "market is ended");
        // check MIN_ORDER
        uint256 avaiableBalance = mainContract.getAvaiableBalance(msg.sender);
        require(avaiableBalance > _amountToken, "not enough balance");
        
        // solve
        amountUSD = _amountToken.mul(mainContract.TOKEN_PRICE_USD()).div(10**6);                   // convert GEX to USD
        if(_status == true)
            marketStatistic[_marketID].upTotal += amountUSD;
        else
            marketStatistic[_marketID].downTotal += amountUSD;
        
        mainContract.subtractBalance(msg.sender, _amountToken);
        
        marketOrders[_marketID][marketStatistic[_marketID].countOrder].amount = _amountToken;
        marketOrders[_marketID][marketStatistic[_marketID].countOrder].user = msg.sender;
        marketOrders[_marketID][marketStatistic[_marketID].countOrder].status = _status;
        marketOrders[_marketID][marketStatistic[_marketID].countOrder].payWith = false; // payWith = false = GEX
        
        marketStatistic[_marketID].countOrder++;
        
        if(_status == true)
            marketStatistic[_marketID].upCount++;
        else
            marketStatistic[_marketID].downCount++;
        
        // save statistic and emit event
        statistic[msg.sender].totalOrder++;
        statistic[msg.sender].totalAmountOrder += amountUSD;
        // bonus token for sender
        statistic[msg.sender].totalTokenBonus += addBonus(msg.sender,amountUSD);
        
        emit NewOrder(_marketID, msg.sender, _status, _amountToken, false);
        return true;
    }
    
    function () public payable {
        // thank for donate
    }
}