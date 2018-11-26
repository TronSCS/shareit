
pragma solidity ^0.4.24;

// ----------------------------------------------------------------------------
// ERC Token Standard #20 Interface
// https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20-token-standard.md
// ----------------------------------------------------------------------------
contract ERC20Interface {
    function totalSupply() public constant returns (uint);
    function balanceOf(address tokenOwner) public constant returns (uint balance);
      function transfer(address to, uint tokens) public returns (bool success);
      
    //function allowance(address tokenOwner, address spender) public constant returns (uint remaining);
   // function approve(address spender, uint tokens) public returns (bool success);
    //function transferFrom(address from, address to, uint tokens) public returns (bool success);

    event Transfer(address indexed from, address indexed to, uint tokens);
   // event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}

contract token_no_decimals2 is ERC20Interface{
    string public name = "tokenNoDecimalsAtAll2";
    string public symbol = "tokenNoDec2";
    uint public decimals = 0;
    
    uint public supply; 
    address public founder;
    
    mapping(address => uint) public balances;
    
    event Transfer(address indexed from, address indexed to, uint tokens);
    
    constructor() public{
        supply = 1000000;
        founder = msg.sender;
        balances[founder] = supply;
    }
    
     function totalSupply() public constant returns (uint){
         return supply;
     }
     
      function balanceOf(address tokenOwner) public constant returns (uint balance) {
          return balances[tokenOwner];
      }
      
         function transfer(address to, uint tokens) public returns (bool success){

         require(balances[msg.sender] >= tokens && tokens > 0);
         
         balances[to] += tokens;
         balances[msg.sender] -= tokens;
         emit Transfer(msg.sender, to, tokens);
         return true;
      }
    
}