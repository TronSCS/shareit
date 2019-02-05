pragma solidity ^0.4.24;

import "./OracleTicker.sol";

contract SafeMath {
  function safeMul(uint a, uint b) pure public returns (uint) {
    uint c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }
  function safeSub(uint a, uint b) pure public returns (uint) {
    assert(b <= a);
    return a - b;
  }
  function safeAdd(uint a, uint b) pure public returns (uint) {
    uint c = a + b;
    assert(c>=a && c>=b);
    return c;
  }
}
contract Token {
  /// @return total amount of tokens
  function totalSupply() constant public returns (uint256 supply) {}

  /// @param _owner The address from which the balance will be retrieved
  /// @return The balance
  function balanceOf(address _owner) constant returns (uint256 balance) {}

  /// @notice send `_value` token to `_to` from `msg.sender`
  /// @param _to The address of the recipient
  /// @param _value The amount of token to be transferred
  /// @return Whether the transfer was successful or not
  function transfer(address _to, uint256 _value) returns (bool success) {}

  /// @notice send `_value` token to `_to` from `_from` on the condition it is approved by `_from`
  /// @param _from The address of the sender
  /// @param _to The address of the recipient
  /// @param _value The amount of token to be transferred
  /// @return Whether the transfer was successful or not
  function transferFrom(address _from, address _to, uint256 _value) returns (bool success) {}

  /// @notice `msg.sender` approves `_addr` to spend `_value` tokens
  /// @param _spender The address of the account able to transfer the tokens
  /// @param _value The amount of wei to be approved for transfer
  /// @return Whether the approval was successful or not
  function approve(address _spender, uint256 _value) returns (bool success) {}

  /// @param _owner The address of the account owning tokens
  /// @param _spender The address of the account able to transfer the tokens
  /// @return Amount of remaining tokens allowed to spent
  function allowance(address _owner, address _spender) constant returns (uint256 remaining) {}

  event Transfer(address indexed _from, address indexed _to, uint256 _value);
  event Approval(address indexed _owner, address indexed _spender, uint256 _value);

  uint public decimals;
  string public name;
}

contract StandardToken is Token {
  function transfer(address _to, uint256 _value) returns (bool success) {
    //Default assumes totalSupply can't be over max (2^256 - 1).
    //If your token leaves out totalSupply and can issue more tokens as time goes on, you need to check if it doesn't wrap.
    //Replace the if with this one instead.
    if (balances[msg.sender] >= _value && balances[_to] + _value > balances[_to]) {
    //if (balances[msg.sender] >= _value && _value > 0) {
      balances[msg.sender] -= _value;
      balances[_to] += _value;
      emit Transfer(msg.sender, _to, _value);
      return true;
    } else { return false; }
  }

  function transferFrom(address _from, address _to, uint256 _value) returns (bool success) {
    if (balances[_from] >= _value && allowed[_from][msg.sender] >= _value && balances[_to] + _value > balances[_to]) {
      balances[_to] += _value;
      balances[_from] -= _value;
      allowed[_from][msg.sender] -= _value;
      emit Transfer(_from, _to, _value);
      return true;
    } else { return false; }
  }

  function balanceOf(address _owner) constant returns (uint256 balance) {
    return balances[_owner];
  }

  function approve(address _spender, uint256 _value) returns (bool success) {
    allowed[msg.sender][_spender] = _value;
    emit Approval(msg.sender, _spender, _value);
    return true;
  }

  function allowance(address _owner, address _spender) constant returns (uint256 remaining) {
    return allowed[_owner][_spender];
  }

  mapping(address => uint256) balances;

  mapping (address => mapping (address => uint256)) allowed;

  uint256 public totalSupply;
}

contract EtherCallBet is SafeMath{
  uint minBetValue = 0;
  uint maxBetValue = 0;
  uint minBetFeeValue = 0;
  uint maxBetFeeValue = 0;
  uint8 UserRefPcnt = 0; // User's ref 15 is 1.5%
  uint8 RefRefPcnt = 0;  // Referral's ref (upper referrer) 5 is 0.5%
  uint8 SHAPcnt = 0;     // SHARE percentage 400 is 40.0% for the first time
  uint8 OSHAPcnt = 0;    // OSHARE percentage 50 is 5.0% for the first time
  uint ownerFeeValue = 0;
  uint256 SHAdepo = 0;   // share values
  uint256 OSHAdepo = 0;  // owners share value
  uint8 ShaPcnt = 0;   // SHARE percentage 400 is 40.0% for the first time
  uint8 OShaPcnt = 0;   // OSHARE percentage 50 is 5.0% for the first time
  uint ContractDepo = 0; // contract depo for making awards
  uint256 freezedSHA = 0;   // freezed SHA values from token holders to share rewards
  uint256 freezedOSHA = 0;  // freezed OSHA values from token holders to share rewards
  address public owner;
  address public OraclePulsarAddress = 0x0; // ticker contract address
  address public ShareMasterAddress = 0x0;  // Share master address
  address[] freezedShaAccountList; // todo: Current freezed account list, it always growing, need to be shortened by external oracle
  address[] freezedOShaAccountList; // todo: Current freezed account list, it always growing, need to be shortened by external oracle
  OracleTicker Ticker;
  address tokenAddress = 0x0; //Game token
  address tokenShaAddress = 0x0;  //SHA token
  address tokenOShaAddress = 0x0; //OSHA token
  string constant _SHA = "SHA";
  string constant _OSHA = "OSHA";
  uint256 maxTokens = 0;
  StandardToken UtilityToken;

  event BetOpened(string _betKey);
  event BetClosed(string _betKey);
  event Award(address indexed _from, string indexed _betKey, string _type, uint256 _stake, string _resCode, uint256 _resValue);
  event Deposite(address indexed _from, uint256 _depoValue);
  event Withdraw(address indexed _from, uint256 _withdrawValue);
  event DepositeToContract(address indexed _from, uint256 _depoValue);
  event WithdrawFromContract(address indexed _from, uint256 _withdrawValue);
  event BetUp(address indexed _from, string indexed _betKey, uint256 _resValue);
  event BetDown(address indexed _from, string indexed _betKey, uint256 _resValue);
  event PvCStake(address indexed _from, string indexed _betKey, string indexed _gameKind, bytes1 _prediction, uint256 _stakeValue);

  // Only owner can do
  modifier onlyOwner {
    require(owner == msg.sender);
    _;
  }
  // Only Oracle Pulsar can do
  modifier onlyOraclePulsar {
    require(OraclePulsarAddress == msg.sender);
    //if (OraclePulsarAddress != msg.sender) throw;
    _;
  }
  modifier onlyShareMaster {
    require(OraclePulsarAddress == msg.sender);
    //if (OraclePulsarAddress != msg.sender) throw;
    _;
  }
  // bet states
  struct betState{
      bool isStarted;
      bool isStoped;
      bool isAwarded;
  }
  struct betForArray{
      address   gamerAccount;
      uint      BetValue;
      uint      BetFeeValue;
  }
  // set for betting to faster get element in array, by betKey, and account we can easy get number in bet array
  struct betForSet{
      //mapping (address => elementNumber) element;
      betForArray[] bets;
  }
  // structure for gamer deposite
  struct gamerDeposite{
      uint      gamerDepoVal;
  }
  // structure for period
  struct periodData{
    uint256 freezedTokens;
    uint256 depositedTokens;
    mapping (address => uint256) addressFrozenValue;
    mapping (address => uint256) addressRewardsValue;
    address[] rewardAddresses;
    address[] awardedAddresses;
  }

  mapping (string => betState) private betKeyStates;

  // betkeystakes:
  //      betkey => gamekind
  mapping(string =>
          //     gamekind=>account
          mapping(string =>
                  //      account => prediction
                  mapping(address =>
                          //     prediction=>stakevalue
                          mapping(bytes1 => uint)))) private betKeyStakes;
    // Address awarded at this betkey
    //      betkey => gamekind
    mapping (string =>
            // gamekind=> account
            mapping(string =>
                    //      account => awarded
                    mapping (address => bool))) private betKeyGameAdressAwarded;

  // Address awarded at this betkey
  // mapping (string => mapping (address => bool)) private betKeyAdressAwarded;
  // Upper event
  mapping (string => betForSet) private betForSetUpper;
  // Lower event
  mapping (string => betForSet) private betForSetLower;
  // gamerDepo
  mapping (address => gamerDeposite) private gamerDepo;
  // statePairTFOracles[pairTF] == addressOracle
  mapping (string => address) private statePairTFOracles;
  // Remember last opened bar for pair & tf
  mapping (string => string) private lastBars;
  // RefAlias - Ref
  mapping (string => address) private refAlias;
  // Remember gamer's referrer we register G1 from Ref1 GamersReferrer[G1] = Ref1 G1->Ref1, and we probably have Ref1->Ref2
  mapping (address => address) private GamersReferrer;
  // Reward periods for SHA and OSHA award models
  mapping (string => uint256) private rewardPeriod;
  // Freezed SHA / OSHA by account, account -> tokenKind -> value
  mapping(address => mapping(string => uint256)) private freezedAccountKind;
  // SHA/OSHA -> Period -> {address-reward, addressrewards[], addressawarded[]}
  mapping(string => mapping(uint256 => periodData)) private tokenPeriodData;
  
  // Set Oracle for Pair TimeFrame
  function SetPairTFOracles(string pairTF, address addressOracle) public onlyOwner {
    statePairTFOracles[pairTF] = addressOracle;
  }
  // Read gamer depo
  function GetCurrentDepo() public view returns (uint) {
    return(gamerDepo[msg.sender].gamerDepoVal);
  }
  // Make bet to upper event on specified bet key
  function MakeBetUpper(string betKey, uint BetValue, uint BetFeeValue) public{
    require(
      bytes(betKey).length > 0 &&
      BetValue >= minBetValue && BetFeeValue >= minBetFeeValue &&
      betKeyStates[betKey].isStarted &&
      !betKeyStates[betKey].isStoped &&
      !betKeyStates[betKey].isAwarded &&
      gamerDepo[msg.sender].gamerDepoVal >= (BetValue + BetFeeValue)
    );
    // Go throw all array elems and if account found change data if not found
    bool bFound = false;
    for (uint i = 0; i < betForSetUpper[betKey].bets.length; i++) {
      if (betForSetUpper[betKey].bets[i].gamerAccount == msg.sender) {
        betForSetUpper[betKey].bets[i].BetValue     += BetValue;
        betForSetUpper[betKey].bets[i].BetFeeValue  += BetFeeValue;
        bFound = true;
      }
    }
    if (!bFound) {
        betForArray memory ValueToAdd;
        ValueToAdd.gamerAccount = msg.sender;
        ValueToAdd.BetValue     = BetValue;
        ValueToAdd.BetFeeValue  = BetFeeValue;
        betForSetUpper[betKey].bets.push(ValueToAdd);
    }
    gamerDepo[msg.sender].gamerDepoVal -= (BetValue + BetFeeValue);
    ownerFeeValue += BetFeeValue;
    emit BetUp(msg.sender, betKey, BetValue);
  }
  // Make bet to lower event on specified bet key
  function MakeBetLower(string betKey, uint BetValue, uint BetFeeValue) public{
    require(
      bytes(betKey).length > 0 &&
      BetValue >= minBetValue && BetFeeValue >= minBetFeeValue &&
      betKeyStates[betKey].isStarted &&
      !betKeyStates[betKey].isStoped &&
      !betKeyStates[betKey].isAwarded &&
      gamerDepo[msg.sender].gamerDepoVal >= (BetValue + BetFeeValue)
      );
      // Go throw all array elems and if account found change data if not found
      bool bFound = false;
      for (uint i = 0; i < betForSetLower[betKey].bets.length; i++) {
        if (betForSetLower[betKey].bets[i].gamerAccount == msg.sender) {
          betForSetLower[betKey].bets[i].BetValue     += BetValue;
          betForSetLower[betKey].bets[i].BetFeeValue  += BetFeeValue;
          bFound = true;
        }
      }
      if (!bFound) {
          betForArray memory ValueToAdd;
          ValueToAdd.gamerAccount = msg.sender;
          ValueToAdd.BetValue     = BetValue;
          ValueToAdd.BetFeeValue  = BetFeeValue;
          betForSetLower[betKey].bets.push(ValueToAdd);
      }
    gamerDepo[msg.sender].gamerDepoVal  -= (BetValue + BetFeeValue);
    ownerFeeValue += BetFeeValue;
    emit BetDown(msg.sender, betKey, BetValue);
  }
  function GetMyBetUpper(string betKey) public view
    returns(address gamerAddress, uint BetValue, uint BetFeeValue) {
      require(bytes(betKey).length > 0);
      for (uint i = 0; i < betForSetUpper[betKey].bets.length; i++) {
        if (betForSetUpper[betKey].bets[i].gamerAccount == msg.sender) {
          BetValue    = betForSetUpper[betKey].bets[i].BetValue;
          BetFeeValue = betForSetUpper[betKey].bets[i].BetFeeValue;
          break;
        }
      }
      return(
        msg.sender,
        BetValue,
        BetFeeValue
      );
  }
  function GetMyBetLower(string betKey) public view
    returns(address gamerAddress, uint BetValue, uint BetFeeValue) {
      require(bytes(betKey).length > 0);
      for (uint i = 0; i < betForSetLower[betKey].bets.length; i++) {
        if (betForSetLower[betKey].bets[i].gamerAccount == msg.sender) {
          BetValue    = betForSetLower[betKey].bets[i].BetValue;
          BetFeeValue = betForSetLower[betKey].bets[i].BetFeeValue;
          break;
        }
      }
      return(
        msg.sender,
        BetValue,
        BetFeeValue
      );
  }
  // Start betting on some bet key
  function StartBet(string pairTF, string betKey) public {
    require (
      (
        statePairTFOracles[pairTF] == msg.sender ||
        OraclePulsarAddress == msg.sender
      ) &&
      !betKeyStates[betKey].isStarted &&
      !betKeyStates[betKey].isStoped &&
      !betKeyStates[betKey].isAwarded);
    betKeyStates[betKey].isStarted = true;
    lastBars[pairTF] = betKey;
    emit BetOpened(betKey);
  }
  // Stop betting on some bet key
  function StopBet(string pairTF, string betKey) public {
    require (
      (
        statePairTFOracles[pairTF] == msg.sender ||
        OraclePulsarAddress == msg.sender
      ) &&
      betKeyStates[betKey].isStarted &&
      !betKeyStates[betKey].isStoped &&
      !betKeyStates[betKey].isAwarded);
    betKeyStates[betKey].isStoped = true;
    emit BetClosed(betKey);
  }
  // Calculate share from some value
  function CalcShare(uint InputShare, uint SumShares, uint Value) public pure
    returns (uint OutputShare) {
      if (SumShares <= 0){
        return 0;
      }
      else{
        return (((InputShare * 10 ** 3 / SumShares) * Value) / 10 ** 3);
      }
    }
  //
  /*function CanAward(string pairTF) public returns(bool){
    return(
      statePairTFOracles[pairTF] == msg.sender ||
      OraclePulsarAddress == msg.sender);
  }*/
  // Check existence of refAlias
  function isrefAliasTaken(string memory _refAlias) public view returns(bool res) {
    res = (refAlias[_refAlias] != address(0x0));
    return res;
  }
  // TakeAlias
  function takeRefAlias(string memory _refAlias) public {
    require(!isrefAliasTaken(_refAlias));
    refAlias[_refAlias] = msg.sender;
  }
  // Show refAlias - Address
  function getRefAliasAddress(string memory _refAlias) public view returns (address) {
    return(refAlias[_refAlias]);
  }
  // Ref calculator, for percent calculation, inputs WON value and x10 percent 1.5% input is 15
  function CalcRef(uint Won, uint RefPcnt) public pure
    returns(uint outputresult) {
      return (Won * RefPcnt / 1000);
    }
  // Get UserRef and RefRef and make rewards
  function AwardRef(address GamerAcc, uint Won) private {
    address UserRef = address(0x0);
    address RefRef = address(0x0);
    UserRef = GamersReferrer[GamerAcc];
    if (UserRef != address(0x0)) {
      gamerDepo[UserRef].gamerDepoVal += CalcRef(Won, UserRefPcnt);
      RefRef = GamersReferrer[UserRef];
      if (RefRef != address(0x0)) {
        gamerDepo[RefRef].gamerDepoVal += CalcRef(Won, RefRefPcnt);
      }
    }
  }
  /* function GetKeyStakers(string betKey){    GetAwardKindStake(GamerAcc, betKey)  } */
  // set stake on betkey for gamekind of account on prediction the value, stake can be increased
  function makeStake (string memory betKey, string memory gameKind, bytes1 prediction, uint stakeValue) public {
    require (
      bytes(betKey).length > 0 &&
      bytes(gameKind).length > 0 &&
      msg.sender != address(0x0) &&
      stakeValue >= minBetValue && stakeValue <= maxBetValue &&
      gamerDepo[msg.sender].gamerDepoVal >= stakeValue &&
      betKeyStates[betKey].isStarted &&
      !betKeyStates[betKey].isStoped &&
      !betKeyGameAdressAwarded[betKey][gameKind][msg.sender]
    );
    // gamerDepo[msg.sender].gamerDepoVal
    betKeyStakes[betKey][gameKind][msg.sender][prediction] += stakeValue;
    SHAdepo = stakeValue * ShaPcnt / 1000;
    OSHAdepo = stakeValue * OShaPcnt / 1000;
    ContractDepo += stakeValue - SHAdepo - OSHAdepo;
    emit PvCStake(msg.sender, betKey, gameKind, prediction, stakeValue);
  }
  // get users stake info
  function getStakeInfo(string memory betKey, string memory gameKind, bytes1 prediction) public view
    returns (string memory, string memory, bytes1, uint) {
      return(betKey, gameKind, prediction, betKeyStakes[betKey][gameKind][msg.sender][prediction]);
    }

  // Public function to award user account by itself
  function AwardMe(string pairTF, string betKey, string gameKind, bytes1 prediction) public {
    AwardAccount(msg.sender, pairTF, betKey, gameKind, prediction);
  }
  // get n's bit from right in the _input
  function getBit(bytes1 _input, uint8 n) public pure
      returns (bytes1) {
    // n      bit    654321
    // _input binary 111000
        require ((n >= 1) && (n <= 6));
        return bytes1((uint8(_input) >> (n-1)) & 1);
      }
  // get left bits (last), to get left two (11) from 111000, use 4
  function shiftRight(bytes1 a, uint8 n) public pure
      returns (bytes1) {
          require ((n >= 0) && (n <= 5));
          uint8 shifted = uint8(a) / 2 ** n;
          return bytes1(shifted);
      }
  // TODO make function returns all stakers list by betkey, to make it awarded
  function GetAwardKindStake(string betKey, string gameKind, address gamerAcc, bytes1 prediction) private
    returns (uint Stake, uint Won) {
    uint8 O;          // Open
    uint8 H;          // High
    uint8 L;          // Low
    uint8 C;          // Close
    bytes1 b6;       // Byte for next 6 bars 0-current, 1-next and so on
    bytes1 proofb6;  // Byte for proof, bit 1 - proof
    (O, H, L, C, b6, proofb6) = Ticker.getOracleTickerByte(betKey);
    // get Stake Value for betKey, gameKind, for account prediction
    Stake = betKeyStakes[betKey][gameKind][gamerAcc][prediction];
    Won = 0;
    // TODO gameKind and tokenKind need to switch to numbers, to decrease coasts
    //                                              11    11
    if ((keccak256(gameKind) == keccak256("x2"))  && (shiftRight(proofb6, 4) == 0x03)) {
      if (getBit(prediction, 6) == getBit(b6, 6)) {
        if (getBit(prediction, 5) == getBit(b6, 5))      {Won = Stake*2;}
      }
    }
    //                                             111    111
    if ((gameKind == 'x4')  && (shiftRight(proofb6, 3) == 0x07)) {
      if (getBit(prediction, 6) == getBit(b6, 6)) {
        if (getBit(prediction, 5) == getBit(b6, 5)) {
          if (getBit(prediction, 4) == getBit(b6, 4))    {Won = Stake*4;}
          else                                           {Won = Stake/2;}}
      }
    }
    //                                            1111    1111
    if ((gameKind == 'x16') && (shiftRight(proofb6, 2) == 0x0f)) {
      if (getBit(prediction, 6) == getBit(b6, 6)) {
        if (getBit(prediction, 5) == getBit(b6, 5)) {
          if (getBit(prediction, 4) == getBit(b6, 4)) {
            if (getBit(prediction, 3) == getBit(b6, 3))  {Won = Stake*16;}
            else                                         {Won = Stake*2;}}
          else                                           {Won = Stake/2;}}
      }
    }
    //                                           11111    11111
    if ((gameKind == 'x32') && (shiftRight(proofb6, 1) == 0x1f)) {
      if (getBit(prediction, 6) == getBit(b6, 6)) {
        if (getBit(prediction, 5) == getBit(b6, 5)) {
          if (getBit(prediction, 4) == getBit(b6, 4)) {
            if (getBit(prediction, 3) == getBit(b6, 3)) {
              if (getBit(prediction, 2) == getBit(b6, 2)){Won = Stake*32;}
              else                                       {Won = Stake*4;}}
            else                                         {Won = Stake*2;}}
          else                                           {Won = Stake/2;}}
      }
    }
    //                                          111111    111111
    if ((gameKind == 'x64') && (               proofb6 == 0x3f)) {
      if (getBit(prediction, 6) == getBit(b6, 6)) {
        if (getBit(prediction, 5) == getBit(b6, 5)) {
          if (getBit(prediction, 4) == getBit(b6, 4)) {
            if (getBit(prediction, 3) == getBit(b6, 3)) {
              if (getBit(prediction, 2) == getBit(b6, 2)){Won = Stake*32;}
              else                                       {Won = Stake*4;}}
            else                                         {Won = Stake*2;}}
          else                                           {Won = Stake/2;}}
      }
    }
    return (Stake, Won);
  }
  // Core function fo PvC games
  function AwardAccount(address gamerAcc, string pairTF, string betKey, string gameKind, bytes1 prediction) public {
    require (
      gamerAcc != address(0x0) &&
      (
        gamerAcc == msg.sender ||
        statePairTFOracles[pairTF] == msg.sender ||
        OraclePulsarAddress == msg.sender
      ) &&
      // Check award ability globally for betKey
      betKeyStates[betKey].isStarted &&
      betKeyStates[betKey].isStoped);
    // Check personal award ability for betKey
    if (betKeyGameAdressAwarded[betKey][gameKind][gamerAcc]) {
      revert("Account already awarded!");
    }
    uint256 Stake = 0;
    uint256 Won = 0; 
    // Get Gamer's stake and result in WON, positive to award
    (Stake, Won) = GetAwardKindStake(betKey, gameKind, gamerAcc, prediction);
    // is GamerAcc have bet?
    // remove acc from stakers list
    // StakerList[betKey].pop(gamerAcc);
    if (Won>0){
      MakeAward(gamerAcc, betKey, gameKind, Stake, Won);
    } else {
      MakeLoos(gamerAcc, betKey, gameKind, Stake, Won);
    }
    betKeyGameAdressAwarded[betKey][gameKind][gamerAcc] = true;
  }
  // Core function to make award, need all parameters
  function MakeAward(address GamerAcc, string betKey, uint GameKind, uint Stake, uint Won) private {
    require (ContractDepo >= 1.5*Won);                     // if we can
    gamerDepo[GamerAcc].gamerDepoVal += Won;               // Increase player ballance
    AwardRef(GamerAcc, Won);                               // Award ref by won share
    emit Award(GamerAcc, betKey, GameKind, Stake, 'win', Won); // message to client
  }
  // Core function to make award, need all parameters
  function MakeLoos(address GamerAcc, string betKey, uint GameKind, uint Stake, uint Won) private {
    AwardRef(GamerAcc, Stake);                                // Award ref by user's stake share
    emit Award(GamerAcc, betKey, GameKind, Stake, 'loos', Stake); // message to client
  }
  // Award from exact StateOracle-PairTF on some bet key
  function AwardBet(string pairTF, string betKey) public {
    require (
      (
        statePairTFOracles[pairTF] == msg.sender ||
        OraclePulsarAddress == msg.sender
      )&&
      // CanAward(pairTF) &&
      betKeyStates[betKey].isStarted &&
      betKeyStates[betKey].isStoped &&
      !betKeyStates[betKey].isAwarded);

    uint8 O; uint8 H; uint8 L; uint8 C;
    (O, H, L, C) = Ticker.getOracleTicker(betKey);
    if (O <= 0 || H <= 0 || L <= 0 || C <= 0) return;

    uint TotalWinValue = 0;
    uint TotalWinBetsValue = 0;
    uint ShareWinValue = 0;
    uint i = 0;
    uint iValue = 0;
    address tempWinnerAccount = 0x0;

    betKeyStates[betKey].isAwarded = true;
    uint iLowers = betForSetLower[betKey].bets.length;
    uint iUppers = betForSetUpper[betKey].bets.length;
    //Upper bets WIN!
    if (O <= C) {
      // Calculate looser bets
      for (i = 0; i < iLowers; i++) {
        iValue = betForSetLower[betKey].bets[i].BetValue;
        TotalWinValue += iValue;
        // Inform looser lower stakes
        emit Award(betForSetLower[betKey].bets[i].gamerAccount, betKey, 'put', iValue, 'loos', iValue);
      }
      // Calculate winners count
      for (i = 0; i < iUppers; i++) {
        TotalWinBetsValue += betForSetUpper[betKey].bets[i].BetValue;
      }
      // Send winner's share
      ShareWinValue = 0;
      for (i = 0; i < iUppers; i++) {
        tempWinnerAccount = betForSetUpper[betKey].bets[i].gamerAccount;
        iValue = betForSetUpper[betKey].bets[i].BetValue;
        ShareWinValue = CalcShare(iValue, TotalWinBetsValue, TotalWinValue);
        if (ShareWinValue> 0){
          gamerDepo[tempWinnerAccount].gamerDepoVal  += ShareWinValue + iValue;
          // Inform winner upper stakes
          emit Award(tempWinnerAccount, betKey, 'call', iValue, 'win', ShareWinValue);
        }
      }
    } else {
      //Lower bets WIN!
      // Calculate looser bets
      for (i = 0; i < iUppers; i++) {
        iValue = betForSetUpper[betKey].bets[i].BetValue;
        TotalWinValue += iValue;
        // Inform looser lower stakes
        emit Award(betForSetUpper[betKey].bets[i].gamerAccount, betKey, 'call', iValue, 'loos', iValue);
      }
      // Calculate winners count
      for (i = 0; i < iLowers; i++) {
        TotalWinBetsValue += betForSetLower[betKey].bets[i].BetValue;
      }
      // Send winner's share
      ShareWinValue = 0;
      for (i = 0; i < iLowers; i++) {
        tempWinnerAccount = betForSetLower[betKey].bets[i].gamerAccount;
        iValue = betForSetLower[betKey].bets[i].BetValue;
        ShareWinValue = CalcShare(iValue, TotalWinBetsValue, TotalWinValue);
        if (ShareWinValue> 0){
          //send ShareWinValue to betForSetLower[betKey].bets[i].gamerAccount
          gamerDepo[tempWinnerAccount].gamerDepoVal  += ShareWinValue + iValue;
          // Inform winner lower stakes
          emit Award(tempWinnerAccount, betKey, 'put', iValue, 'win', ShareWinValue);
        }
      }
    }
  }
  // Reward tokens ///////////////////////////////////
  // SHARE, SHA - gamer reward token, depends on dayly period reward
  // OWNER, OSHA- owners reward token, depends on weekly period reward
  // EVENT TOKEN_kind, minutes for period ending, oracles rules the period length, hourly event
  //
  // All periods starting from some block, by PeriodStart(TOKEN_kind, stakesForReward) -> write block_start for some TOKEN, increase TokenPriod number,
  // {Profit_for_share_reward_token_, Freezed_reward_token} - structure for SHA and OSHA
  // stakesForReward only for SHA, stakes to reward by SHA
  // Share rewards by tokens makes by WriteShare(TOKEN_kind, Token_percent) -> add users deposite tokens to Tokens pool share (in Profit_for_share_reward_token_)
  // for current TokenPriod according Token_percent

  // SetNewPeriod(TOKEN_kind) - set new period for some token kind, save old periods state -> tokenPeriodData
  function SetNewPeriod(string TOKEN_kind) private onlyShareMaster
  returns(uint256 _NewPeriod) {
    require(TOKEN_kind == _OSHA || TOKEN_kind == _SHA);
    uint256 _OldPeriod = GetPeriod(TOKEN_kind);
    // mapping (address => uint256) addressRewardsValue;
    // address[] rewardAddresses;
    // address[] awardedAddresses;
    if (TOKEN_kind == _SHA) {
      tokenPeriodData[TOKEN_kind][_OldPeriod].freezedTokens = freezedSHA;
      tokenPeriodData[TOKEN_kind][_OldPeriod].depositedTokens = SHAdepo;
      tokenPeriodData[TOKEN_kind][_OldPeriod].rewardAddresses = freezedShaAccountList; // todo: We need to short it by Oracle and send BACK
      freezedShaAccountList = []; // reset freezedAccountList
      freezedSHA = 0;
      SHAdepo = 0;
      _NewPeriod = _OldPeriod + 1;
    } else {
      tokenPeriodData[TOKEN_kind][_OldPeriod].freezedTokens = freezedOSHA;
      tokenPeriodData[TOKEN_kind][_OldPeriod].depositedTokens = OSHAdepo;
      tokenPeriodData[TOKEN_kind][_OldPeriod].rewardAddresses = freezedOShaAccountList; // todo: We need to short it by Oracle and send BACK
      freezedOShaAccountList = []; // reset freezedAccountList
      freezedOSHA = 0;
      OSHAdepo = 0;
      _NewPeriod = _OldPeriod + 1;
    }
    tokenPeriodData[TOKEN_kind][_OldPeriod].awardedAddresses = []; // At close time nobody awarded, this field will be filled by Oracle later after sending awards
    return(_NewPeriod);
    // mapping(string => mapping(uint256 => periodData)) private tokenPeriodData;
    /*
    struct periodData{
      mapping (address => uint256) addressRewardsValue;
      address[] rewardAddresses;
      address[] awardedAddresses;
    }
    */
  }
  // Get address array for token for some period
  function GetAccountsForPeriodToken(string TOKEN_kind, uint256 _period) private view onlyShareMaster
  returns(address[]) {
    return(tokenPeriodData[TOKEN_kind][_period].rewardAddresses);
  }

  // Add new shortened array to freezed account list
  function AddAccountsForPeriodToken(string TOKEN_kind, uint256 _period, address[] _accountsARR) private onlyShareMaster{
    if (TOKEN_kind == _SHA) {
      freezedShaAccountList.push(_accountsARR); // reset freezedAccountList
    }
    else {
      freezedOShaAccountList.push(_accountsARR); // reset freezedAccountList
    }
    tokenPeriodData[TOKEN_kind][_period].rewardAddresses = _accountsARR;
  }

  // Instantly return freezed accounts list at the moment
  function GetFreezedAccountsToken(string TOKEN_kind) private onlyShareMaster returns (address[]) {
    if (TOKEN_kind == _SHA) {
      return(freezedShaAccountList);
    } else {
      return(freezedOShaAccountList);
    }
  }

  // GetPeriod(TOKEN_kind) - returns period for some token kind
  function GetPeriod(string TOKEN_kind) public view returns (uint256) {
    return(rewardPeriod[TOKEN_kind]);
  }

  // Only freezed tokens will be eligible for rewards
  // Freezed_token_kind structure {Period, Address, Amount, DividentsPaidOut}
  // Freeze(TOKEN_kind) - deposite own tokens on contract (public user) updates structure {Freezed_reward_token}
  // no events!!!  EVENT Address, Amount, Freez
  function freezToContract(uint _amount, address _tokenAddress) public {
    require(_tokenAddress == tokenShaAddress || _tokenAddress == tokenOShaAddress);
    require(_amount > 0);
    require(_amount <= maxTokens);
    uint256 _period = 0; 
    if (Token(_tokenAddress).balanceOf(msg.sender) < _amount) {
      revert("Insufficient balance to freeze!");
    }
    if (_tokenAddress == tokenShaAddress) {
      if (Token(_tokenAddress).transferFrom(msg.sender, this, _amount)) {
        _period = GetPeriod(_SHA);
        freezedSHA += _amount;
        freezedAccountKind[msg.sender][_SHA] += _amount;
        tokenPeriodData[_SHA][_period].addressFrozenValue[msg.sender] += _amount;
      }
    }
    if (_tokenAddress == tokenOShaAddress) {
      if (Token(_tokenAddress).transferFrom(msg.sender, this, _amount)) {
        _period = GetPeriod(_OSHA);
        freezedOSHA += _amount;
        freezedAccountKind[msg.sender][_OSHA] += _amount;
        tokenPeriodData[_OSHA][_period].addressFrozenValue[msg.sender] += _amount;
      }
    }
  }
  // UnFreeze(TOKEN_kind) - withdraw own tokens from contract (public user) updates structure {Freezed_reward_token}
  // no Events!!! EVENT Address, Amount, UnFreez
  function unFreezFromContract(uint _amount, address _tokenAddress) public {
    require(_tokenAddress == tokenShaAddress || _tokenAddress == tokenOShaAddress);
    require(_amount > 0);
    require(_amount <= maxTokens);
    require(freezedAccountKind[msg.sender][_SHA] >= _amount || freezedAccountKind[msg.sender][_OSHA] >= _amount);
    if (_tokenAddress == tokenShaAddress) {
      if (Token(_tokenAddress).transfer(msg.sender, _amount)) {
        freezedSHA -= _amount;
        freezedAccountKind[msg.sender][_SHA] -= _amount;
      }
    }
    if (_tokenAddress == tokenOShaAddress) {
      if (Token(_tokenAddress).transfer(msg.sender, _amount)) {
        freezedOSHA -= _amount;
        freezedAccountKind[msg.sender][_OSHA] -= _amount;
      }
    }
  }
  // SHA/OSHA -> Period -> {address-reward, addressrewards[], addressawarded[]}
  // CalcRewards(TOKEN_kind, period, address)
  function CalcRewards(string TOKEN_kind, uint256 _period, address _address) private view onlyShareMaster
  returns(uint256 _rewardValue) {
    // mapping(string => mapping(uint256 => periodData)) private tokenPeriodData;
    // Calculate reward for account for token
    uint256 TotalRewards  = tokenPeriodData[TOKEN_kind][_period].depositedTokens;
    uint256 AccountFrozen = tokenPeriodData[TOKEN_kind][_period].addressFrozenValue[_address];
    uint256 TotalFrozen   = tokenPeriodData[TOKEN_kind][_period].freezedTokens;
    // uint256 AccountShare = AccountFrozen / TotalFrozen;
    return (TotalRewards * AccountFrozen / TotalFrozen);
  }
  // PayRewardsBatch(TOKEN_kind, period, address[], addr_cnt)
  function PayRewardsBatch(string TOKEN_kind, uint256 period, address[] _addressBATCH, uint256 addr_cnt) private onlyShareMaster{
    uint256 _reward = 0;
    for (uint256 i = 0; i < addr_cnt-1; i++) {
      _reward = CalcRewards(TOKEN_kind, period, _addressBATCH[i]);
      PayRewardsAccount(TOKEN_kind, period, _addressBATCH[i], _reward);
      _reward = 0;
    }
  }
  // Pay rewards to account,
  function PayRewardsAccount(string TOKEN_kind, uint256 _period, address _address, uint256 _reward) private onlyShareMaster{
    tokenPeriodData[TOKEN_kind][_period].awardedAddresses.push(_address);
    tokenPeriodData[TOKEN_kind][_period].addressRewardsValue[_address] = _reward;
    gamerDepo[_address].gamerDepoVal += _reward;
  }
  // PayRewardsAddr(TOKEN_kind, period, address)
  // DeleteRewardsArr(TOKEN_kind, period)
  // GetArraysCount(TOKEN_kind, period) -> toreward, awarded
  // GetAddressReward(TOKEN_kind, period, Address) -> value
  // CalcMyCurrentRewards(TOKEN_kind, period) - get contracts structure {Profit_for_share_reward_token_, Freezed_reward_token} and Freezed_token_kind structure {address, amount}
  // and get rewards in tokens for period (0 - current)
  //
  // After new period starts, oracles must pay all dividents fo each address for previouse period
  // WriteDividents(TOKEN_kind, period, address, DividensAmount) - update Freezed_token_kind structure {Period, Address, Amount, DividentsPaidOut} - (oracle user)

  // Get betting state on some bet key
  function GetBetState(string betKey) public view
    returns (bool isStarted, bool isStoped, bool isAwarded) {
      return(betKeyStates[betKey].isStarted, betKeyStates[betKey].isStoped, betKeyStates[betKey].isAwarded);
  }
  // get owner accumulated fee, deprecated
  function GetOwnerFeeValue() public view
    returns (uint) {
        return(ownerFeeValue);
  }
  constructor() public{
    minBetValue = 100;
    maxBetValue = 10000000;
    minBetFeeValue = 10;
    maxBetFeeValue = 100000;
    UserRefPcnt = 15; // User's ref 15 is 1.5%
    RefRefPcnt = 5;   // Referral's ref (upper referrer) 5 is 0.5%
    ShaPcnt = 400;    // SHARE percentage 400 is 40.0% for the first time
    OShaPcnt = 50;    // OSHARE percentage 50 is 5.0% for the first time
    SHAdepo = 0;      // share values
    OSHAdepo = 0;     // owners share value
    rewardPeriod["SHA"] = 0;  // set period to 0
    rewardPeriod["OSHA"] = 0; // set period to 0
    ownerFeeValue = 0;
    ContractDepo = 0;
    maxTokens = 100000000;
    owner = msg.sender;
    //address token,
  }
  function SetContractConf(uint _minBetValue, uint _maxBetValue, uint _minBetFeeValue,
    uint _maxBetFeeValue, uint8 _UserRefPcnt, uint8 _RefRefPcnt) public onlyOwner {
    if (minBetValue != _minBetValue) {minBetValue = _minBetValue;}
    if (maxBetValue != _maxBetValue) {maxBetValue = _maxBetValue;}
    if (minBetFeeValue != _minBetFeeValue) {minBetFeeValue = _minBetFeeValue;}
    if (maxBetFeeValue != _maxBetFeeValue) {maxBetFeeValue = _maxBetFeeValue;}
    if (UserRefPcnt != _UserRefPcnt) {UserRefPcnt = _UserRefPcnt;}
    if (RefRefPcnt != _RefRefPcnt) {RefRefPcnt = _RefRefPcnt;}
  }
  // set oracle ticker address
  function SetTokenAddress(address theUtilityToken) public onlyOwner {
    tokenAddress = theUtilityToken;
  }
  // set oracle address
  function SetTickerAddress(address theNewAddress) public onlyOwner {
    Ticker = OracleTicker(theNewAddress);
  }
  // set oracle ticker address
  function SetOraclePulsarAddress(address theNewAddress) public onlyOwner {
    OraclePulsarAddress = theNewAddress;
  }
  function SetShareMasterAddress(address theNewAddress) public onlyOwner{
    ShareMasterAddress = theNewAddress;
  }
  // deposite token to contract to make bet
  function depositToken(uint amount, address aRefferrer) public {
    require(amount > 0 & msg.sender != address(0x0));
    // if (msg.value>0 || tokenAddress==0) revert();
    //bool res = true;
    // res = Token(/*token*/tokenAddress).transferFrom(msg.sender, this, amount);
    // if (!res) revert();
    if (Token(/*token*/tokenAddress).transferFrom(msg.sender, this, amount)) {
      ContractDepo += amount;
      gamerDepo[msg.sender].gamerDepoVal += amount;
      emit Deposite(msg.sender, amount);
      // register gamer's referrer if need
      if (aRefferrer != address(0x0)) {
        // if no userref then set ref
        if (GamersReferrer[msg.sender] == address(0x0)) {
          GamersReferrer[msg.sender] = aRefferrer; // first level referrer  5% it's a game ref
        }
      }
    }
  }
  // withdraw token from contract to account
  function withdrawToken(uint amount) public {
    // if (msg.value>0 || tokenAddress==0) revert();
    if (gamerDepo[msg.sender].gamerDepoVal < amount) revert();
    // removed gamerDepo
    // if (!Token(/*token*/tokenAddress).transfer(msg.sender, amount)) throw;
    // Reenterance vuln only for ether/trx transfer
    if (Token(/*token*/tokenAddress).transfer(msg.sender, amount)) {
      ContractDepo -= amount;
      gamerDepo[msg.sender].gamerDepoVal = safeSub(gamerDepo[msg.sender].gamerDepoVal, amount);
      emit Withdraw(msg.sender, amount);
    }
  }
  // Make deposite to contract, add tokens to ContractDepo
  function depositToContract(uint amount) public onlyOwner {
    require(amount > 0);
    if (Token(/*token*/tokenAddress).transferFrom(msg.sender, this, amount)) {
      ContractDepo += amount;
      emit DepositeToContract(msg.sender, amount);
    }
  }
  // Make withdraw from contract, withdraw tokens to ContractDepo
  function withdrawFromContract(uint amount) public onlyOwner {
    require(ContractDepo >= amount);
    if (Token(/*token*/tokenAddress).transfer(msg.sender, amount)) {
      ContractDepo = safeSub(ContractDepo, amount);
      emit WithdrawFromContract(msg.sender, amount);
    }
  }

  function GetAllBetsUpper(string betKey) public view
    returns(uint BetValue, uint BetFeeValue) {
      require(bytes(betKey).length > 0);
      for (uint i = 0; i < betForSetUpper[betKey].bets.length; i++) {
          BetValue    += betForSetUpper[betKey].bets[i].BetValue;
          BetFeeValue += betForSetUpper[betKey].bets[i].BetFeeValue;
      }
      return(
        BetValue,
        BetFeeValue
      );
  }
  function GetAllBetsLower(string betKey) public view
    returns(uint BetValue, uint BetFeeValue) {
      require(bytes(betKey).length > 0);
      for (uint i = 0; i < betForSetLower[betKey].bets.length; i++) {
          BetValue    += betForSetLower[betKey].bets[i].BetValue;
          BetFeeValue += betForSetLower[betKey].bets[i].BetFeeValue;
      }
      return(
        BetValue,
        BetFeeValue
      );
  }
  function withdrawOwnerFeeToken(uint amount) onlyOwner public {
    // if (msg.value>0 || tokenAddress==0) revert();
    if (ownerFeeValue < amount) revert("Not enough Fee to withdraw.");
    // if (!Token(tokenAddress).transfer(owner, amount)) throw;
    if (Token(tokenAddress).transfer(owner, amount)) {
      ownerFeeValue = safeSub(ownerFeeValue, amount);
    }
  }
  // returns last tick for tick pair & tf
  function getLastBarbyPairTF(string pairTf) public view
    returns (string) {
      return(lastBars[pairTf]);
    }
}

// migrate --reset --compile-all --network testprivate
// migrate --reset --compile-all --network development
// migrate --reset --compile-all --network kovan
// var bet1 = EtherCallBet.at(EtherCallBet.address)
// bet1.GetOwnerFeeValue()
// bet1.MakeDepo(100000)
// bet1.GetCurrentDepo()
// var tick1 = OracleTicker.at(OracleTicker.address)
// bet1.SetTickerAddress(tick1.address)
// tick1.setOracleTicker('EURUSD_M30_20171130_223000', 1000, 2000, 500, 1300)
// tick1.getOracleTicker('EURUSD_M30_20171130_223000')
// bet1.StartBet('EURUSD_M30_20171130_223000')
// bet1.GetBetState('EURUSD_M30_20171130_223000')
// bet1.MakeBetUpper('EURUSD_M30_20171130_223000', 1000, 100)
// bet1.MakeBetLower('EURUSD_M30_20171130_223000', 2000, 200)
// bet1.GetMyBetLower('EURUSD_M30_20171130_223000')
// bet1.GetMyBetUpper('EURUSD_M30_20171130_223000')
// bet1.StopBet('EURUSD_M30_20171130_223000')
// bet1.AwardBet('EURUSD_M30_20171130_223000')
// bet1.GetCurrentDepo() -- must be "99700"
// bet1.GetOwnerFeeValue() -- must be "300"
// bet1.CalcShare(1000, 1000, 2000)
// bet1.percent(101, 450, 3)
// var gta1 = GTA.at(GTA.address)
// var bin1 = BIN.at(BIN.address)
// bet1.SetTokenAddress(gta1.address)
// bet1.SetTokenAddress(bin1.address)
// tick1.transferOwnership("0xdaC7D403A366533E450AC5e03985779B04f48398") 0x0016c273c382fE00f4E51d5Ce199aC03d61E4582
// bet1.SetOraclePulsarAddress("0x4Ba85b130eCBCE456f10b593f58a68aE9efA2A86") 0x00Cc4A5145AF6dBfb67e2CaA2df637bd475e56C5
// bet1.SetPairTFOracles("BTCUSDT_M5", "0x4Ba85b130eCBCE456f10b593f58a68aE9efA2A86")
// bet1.SetPairTFOracles("BTCUSDT_M15", "0x29609580a495285e85ff9724e4B0025375A3E245")
// tick1.SetPairTFOracles("BTCUSDT_M5", "0xC435A4E5842e36ef4c8543FAe1E8649EEdA05e70")
// tick1.setOracleTicker('BTCUSDT_M5', 'BTCUSDT_M5_20181211_192500', 1, 2, 3, 4, '5', '4', '3', '2', '1')
// tick1.getLastTickbyPairTF('BTCUSDT_M5_20181211_192500')
// "BTCUSDT_M5","BTCUSDT_M5_20181211_192500","10000","20000","500","25000","1","BTCUSDT_M5_20181211_193000","BTCUSDT_M5_20181211_193500","BTCUSDT_M5_20181211_194000","BTCUSDT_M5_20181211_194500","BTCUSDT_M5_20181211_195000"
// tick1.getForwardKeys('BTCUSDT_M5_20181211_192500')
// tick1.getOracleTicker('BTCUSDT_M5_20181211_192500')
// tick1.SetPairTFOracles("BTCUSDT_M15", "0x29609580a495285e85ff9724e4B0025375A3E245")
// gta1.approve(EtherCallBet.address, "100000") -- allow EtherCallBet contract to manage 100000 GTA from user
// bet1.depositToken(/*GTA.address*/, "100000") -- Token(GTA token).transferFrom(msg.sender, this, amount);
// bet1.GetCurrentDepo() -- must be "100000"
// web3.eth.accounts[0] -- default account
// bet1.withdrawToken("100000")
// gta1.balanceOf(web3.eth.accounts[0]) -- 2 000000 000000

// I can make just exchange from one token to another, using GTA as fee
// I can make pay service using GTA as fee

// node1 pwdnode1
// 081fe2714253da41c34de80cc0bf9d8e9a655f47
// node2 pwdnode2
// bce179a1f2bf55ca1ff6b734e8771c71323da680
