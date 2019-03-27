pragma solidity ^0.4.0;

/*
* [✓] 2% Withdraw fee
* [✓] 5% Deposit fee
* [✓] 2% Token transfer
* [✓] 20% Ref link
*
*/

contract TCH {

    modifier onlyBagholders {

        _;
    }

    modifier onlyStronghands {

        _;
    }

    event onTokenPurchase(
        address indexed customerAddress,
        uint256 incomingTron,
        uint256 tokensMinted,
        address indexed referredBy,
        uint timestamp,
        uint256 price
	);

    event onTokenSell(
        address indexed customerAddress,
        uint256 tokensBurned,
        uint256 tronEarned,
        uint timestamp,
        uint256 price
	);

    event onReinvestment(
        address indexed customerAddress,
        uint256 tronReinvested,
        uint256 tokensMinted
	);

    event onWithdraw(
        address indexed customerAddress,
        uint256 tronWithdrawn
	);

    event Transfer(
        address indexed from,
        address indexed to,
        uint256 tokens
	);

    string public name = "TCH";
    string public symbol = "TCH";
    uint8 constant public decimals = 18;
    uint8 constant internal entryFee_ = 5;
    uint8 constant internal transferFee_ = 2;
    uint8 constant internal exitFee_ = 2;
    uint8 constant internal refferalFee_ = 20;
    uint256 constant internal tokenPriceInitial_ = 10000;
    uint256 constant internal tokenPriceIncremental_ = 100;
    uint256 constant internal magnitude = 2 ** 64;

    mapping(address => uint256) internal tokenBalanceLedger_;
    mapping(address => uint256) internal referralBalance_;
    mapping(address => int256) internal payoutsTo_;
    uint256 internal tokenSupply_;
    uint256 internal profitPerShare_;

    function buy(address _referredBy) public payable returns (uint256) {

    }

    function() payable public {
    }

    function reinvest() onlyStronghands public {

        address _customerAddress = msg.sender;
   
    
        referralBalance_[_customerAddress] = 0;
             
    }

    function exit() public {
        address _customerAddress = msg.sender;
        uint256 _tokens = tokenBalanceLedger_[_customerAddress];
        if (_tokens > 0) sell(_tokens);
        withdraw();
    }

    function withdraw() onlyStronghands public {
        address _customerAddress = msg.sender;

     
      
        referralBalance_[_customerAddress] = 0;

    }

    function sell(uint256 _amountOfTokens) onlyBagholders public {
        address _customerAddress = msg.sender;
  
        uint256 _tokens = _amountOfTokens;
   
     
     

  
    

       

        if (tokenSupply_ > 0) {
   
        }
      
    }

    function transfer(address _toAddress, uint256 _amountOfTokens) onlyBagholders public returns (bool) {
        address _customerAddress = msg.sender;
  

  
            withdraw();
        }



    
        
        
        
       
      
      
 
    


   
        
    

  
        
    

    
       
       
    

   

        
    

  
     

   

        // our calculation relies on the token supply, so we need supply. Doh.
    
            
       
      
         
      

          
        
    

  
       
        
     
      
       
          
         
    

     
   
      
   
    

   
      
       
 
     
    


  
        
       
        
    

    
   

      
       
    

      
   
     
        
       
     
    

  
      
 
       

   
 

    
  
           
                  
                       
                                
                         
                              
                            
                
          
        

  
    

      
        
   
          
                    
                    






    





 
        
          
        }
  
    
    
    

 
        
 
    

 

    

  
      