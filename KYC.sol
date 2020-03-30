pragma solidity ^0.5.9;

contract kyc {

  
    address admin;
    
    /*
    Struct for a customer
     */
    struct Customer {
        string userName;   //unique
        string cust_data_hash;  //unique
        bool kycStatus;
        uint8 downvotes; 
        uint8 upvotes;
        address bank;
    }

    /*
    Struct for a Bank
     */
    struct Bank {
        string bankName;
        address ethAddress;   //unique  
        uint8 report;
        uint8 KYC_count;
        bool kycPermission;
        string regNumber;      //unique   
    }

    /*
    Struct for a KYC Request
     */
    struct KYCRequest {
        string userName;  
        address bank;
        string cust_data_hash;  //unique
        bool isAllowed;         // KYC request for a customer is allowed
        
    }

    /*
    Mapping a customer's username to the Customer struct
    We also keep an array of all keys of the mapping to be able to loop through them when required.
     */
    mapping(string => Customer) customers;
    string[] customerNames;

    /*
    Mapping a bank's address to the Bank Struct
    We also keep an array of all keys of the mapping to be able to loop through them when required.
     */
    mapping(address => Bank) banks;
    address[] bankAddresses;

    /*
    Mapping a customer's Data Hash to KYC request captured for that customer.
    This mapping is used to keep track of every kycRequest initiated for every customer by a bank.
     We also keep an array of all keys of the mapping to be able to loop through them when required.
     */
    mapping(string => KYCRequest) kycRequests;
    string[] customerDataList;

    /*
    Mapping a customer's user name with a bank's address
    This mapping is used to keep track of every upvote given by a bank to a customer
     */
    mapping(string => mapping(address => uint256)) upvotes;
    
    /*
    Mapping a customer's user name with a bank's address
    This mapping is used to keep track of every downvotesvote given by a bank to a customer
     */
    mapping(string => mapping(address => uint256)) downvotes;

    /**
     * Constructor of the contract.
     * We save the contract's admin as the account which deployed this contract.
     */
    constructor() public {
        admin = msg.sender;
    }
    
     /**
     * Modifier of the Admin.
     * This function will restrict access to admin functionalities
     */
    modifier isAdmin() {
       require(admin == msg.sender);
      _;
   }

    /**
     * Record a new KYC request on behalf of a customer
     * The sender of message call is the bank itself
     * @param  {string} _userName The name of the customer for whom KYC is to be done
     * @param  {string} _customerData Hash of the customer's ID submitted for KYC
     * @return {bool}        True if this function execution was successful
     */
    function addKycRequest(string memory _userName, string memory _customerData) public returns (uint8) {
        // Check that the Bank is allowed to perform KYC.
        require(banks[kycRequests[_customerData].bank].kycPermission, "This bank cannot perform any KYC.");
        
        // Check that the user's KYC has not been done before, the Bank is a valid bank and it is allowed to perform KYC.
        require(kycRequests[_customerData].bank == address(0), "This user already has a KYC request with same data in process.");
        
        kycRequests[_customerData].cust_data_hash = _customerData;
        kycRequests[_customerData].userName = _userName;
        kycRequests[_customerData].bank = msg.sender;
        kycRequests[_customerData].isAllowed = true;
        customerDataList.push(_customerData);
        return 1;
    }

    /**
     * Add a new customer
     * @param {string} _userName Name of the customer to be added
     * @param {string} _hash Hash of the customer's ID submitted for KYC
     * @return {uint8}         A 0 indicates failure, 1 indicates success
     */
    function addCustomer(string memory _userName, string memory _customerData) public returns (uint8) {
        if(isValidBank(msg.sender) == 1){
             // Check that the Customer already exists in the Customer List
            require(customers[_userName].bank == address(0), "This customer is already present, please call modifyCustomer to edit the customer data");
            
            //Check if KYC request for this Customer is Allowed
            require(kycRequests[_customerData].isAllowed , "This KYC request for this user is not allowed.");
            
            customers[_userName].userName = _userName;
            customers[_userName].cust_data_hash = _customerData;
            customers[_userName].bank = msg.sender;
            customers[_userName].upvotes = 0;
            customers[_userName].downvotes = 0;  
            customers[_userName].kycStatus = true;   //kycStatus
            customerNames.push(_userName);
            return 1;
        }
        
        return 0;
    }

    /**
     * Remove KYC request
     * @param  {string} _userName Name of the customer
     * @param  {string} _customerData Hash of the customer's ID submitted for KYC
     * @return {uint8}         A 0 indicates failure, 1 indicates success
     */
    function removeKYCRequest(string memory _userName,string memory _customerData) public returns (uint8) {
        uint8 i=0;
        
        for (uint256 i = 0; i< customerDataList.length; i++) {
            if (stringsEquals(kycRequests[customerDataList[i]].userName,_userName)) {
                delete kycRequests[customerDataList[i]];
                for(uint j = i+1;j < customerDataList.length;j++) 
                { 
                    customerDataList[j-1] = customerDataList[j];
                }
                customerDataList.length --;
                i=1;
            }
        }
        return i; // 0 is returned if no request with the input username is found.
    }

    /**
     * Remove customer information
     * @param  {string} _userName Name of the customer
     * @return {uint8}         A 0 indicates failure, 1 indicates success
     */
    function removeCustomer(string memory _userName) public returns (uint8) {
        
        if(isValidBank(msg.sender) == 1){
            
            //Check if Customer's Bank is valid
            require(customers[_userName].bank != address(0), "This customer' bank is not valid.");
            
            for(uint i = 0;i < customerNames.length;i++) 
            { 
                if(stringsEquals(customerNames[i],_userName))
                {
                    delete kycRequests[customers[_userName].cust_data_hash];
                    
                    delete customers[_userName];
                    
                    for(uint j = i+1;j < customerNames.length;j++) 
                    {
                        customerNames[j-1] = customerNames[j];
                    }
                    customerNames.length--;
                    return 1;
                }
                
            }
        }
        
        return 0;
    }

    /**
     * Edit customer information
     * @param  {public} _userName Name of the customer
     * @param  {public} _hash New hash of the updated ID provided by the customer
     * @return {uint8}         A 0 indicates failure, 1 indicates success
     */
    function modifyCustomer(string memory _userName, string memory _newcustomerData) public returns (uint8) {
      if(isValidBank(msg.sender) == 1){
          
        for(uint i = 0;i < customerNames.length;i++) 
            { 
                if(stringsEquals(customerNames[i],_userName))
                {
                    customers[_userName].cust_data_hash = _newcustomerData;
                    customers[_userName].upvotes = 0;
                    customers[_userName].downvotes = 0;
                    removeKYCRequest(_userName,_newcustomerData);
                    return 1;
                }
            
            }
            
      }   
       return 0;
    }

    /**
     * View customer information
     * @param  {public} _userName Name of the customer
     * @return {Customer}         The customer struct as an object
     */
    function viewCustomer(string memory _userName) public view returns (string memory, string memory) {
        return (customers[_userName].userName, customers[_userName].cust_data_hash);
    }

    /**
     * Add a new upvote from a bank
     * @param {public} _userName Name of the customer to be upvoted
     */
    function Upvote(string memory _userName) public returns (uint8) {
        for(uint i = 0;i < customerNames.length;i++) 
            { 
                if(stringsEquals(customerNames[i],_userName))
                {
                    customers[_userName].upvotes++;
                    upvotes[_userName][msg.sender] = now;//storing the timestamp when vote was casted, not required though, additional
                    return 1;
                }
            
            }
            return 0;
        
    }
    
    /**
     * Add a new downvote from a bank
     * @param {public} _userName Name of the customer to be downvoted
     */
    function Downvote(string memory _userName) public returns (uint8) {
        
        for(uint i = 0;i < customerNames.length;i++) 
            { 
                if(stringsEquals(customerNames[i],_userName))
                {
                    customers[_userName].downvotes++;
                    upvotes[_userName][msg.sender] = now;//storing the timestamp when vote was casted, not required though, additional
                    return 1;
                }
            
            }
            return 0;
        
    }
    
     /**
     * Check Validity of the  bank 
     * @param  {public}  _userName Name of the customer whose KYC status is to be updated
     * @return {uint8}  0 indicates failure, 1 indicates success
     */
     function updateCustomerKYCStatus(string memory _userName) public returns(uint8) {
        
          for(uint i = 0;i < customerNames.length;i++) 
            { 
                if((stringsEquals(customerNames[i],_userName)) && (customers[_userName].upvotes > customers[_userName].downvotes))
                {
                    customers[_userName].kycStatus = true;
                    
                    return 1;
                }
                
                if((stringsEquals(customerNames[i],_userName)) && (customers[_userName].downvotes > bankAddresses.length/3))
                {
                    customers[_userName].kycStatus = false;
                    address bankaddress = customers[_userName].bank;
                    banks[bankaddress].kycPermission = false;
                    
                    return 1;
                }
            
            }
        
        return 1;
    }
    
     /**
     * Fetch the Reports of a Bank
     * @param {public} _ethAddress of the bank
     */
    
    function viewBank(address _ethAddress) public view returns(string memory,address,uint8,uint8,bool,string memory) {
       return (banks[_ethAddress].bankName,banks[_ethAddress].ethAddress,banks[_ethAddress].report  , banks[_ethAddress].KYC_count , banks[_ethAddress].kycPermission , banks[_ethAddress].regNumber);
    }
    
    
    
     /**
     * Fetch the KYC status pf the Customer
     * @param {public} _userName Name of the customer 
     */
    
     function getCustomerStatus(string memory _userName) public view returns (bool) {
       return (customers[_userName].kycStatus);
    }
    
    /**
     * View bank information
     * @param  {public} _ethAddress of the bank
     * @return {Bank}    The bank struct as an object
     */
   function getBankReports(address _ethAddress) public view returns(uint) {
       return banks[_ethAddress].report;
   }
   
   /**
     * Add a new customer
     * @param {string} _bankName Name of the bank to be added
     * @param {string} _ethAddress Address of the bank to be added
     * @param {string} _regNumber Reg No of the bank to be added
     */
    function addBank(string memory _bankName,address _ethAddress , string memory _regNumber) isAdmin public returns (uint8) {
        
        
         // Check that the Bank already exists in the Bank List
        require(banks[_ethAddress].ethAddress == address(0), "This bank is already present, please call modifyBank to edit the bank data");
        
        banks[_ethAddress].bankName = _bankName;
        banks[_ethAddress].ethAddress = _ethAddress;
        banks[_ethAddress].report = 0;
        banks[_ethAddress].KYC_count = 0;
        banks[_ethAddress].kycPermission = true;  
        banks[_ethAddress].regNumber = _regNumber;   
        
        return 1;
    }
    
     /**
     * Remove bank information
     * @param  {address} _ethAddress Address of the bank
     * @return {uint8}         A 0 indicates failure, 1 indicates success
     */
    function removeBank(address _ethAddress) isAdmin public returns (uint8) {
            //Check if Bank is valid
            require(banks[_ethAddress].ethAddress != address(0), "This bank is not valid.");
            
            for(uint i = 0;i < bankAddresses.length;i++) 
            { 
                if(bankAddresses[i] == _ethAddress)
                {
                    delete banks[_ethAddress];
                    
                    for(uint j = i+1;j < bankAddresses.length;j++) 
                    {
                        bankAddresses[j-1] = bankAddresses[j];
                    }
                    bankAddresses.length--;
                    return 1;
                }
                
            }
            return 0;
    }
    
    /**
     * Edit bank information
     * @param  {public} _userName Name of the customer
     * @param  {public} _kycPermission of the bank
     * @return {uint8}  0 indicates failure, 1 indicates success
     */
    function modifyBank(address _ethAddress,bool _kycPermission) isAdmin public returns (uint8) {
        for(uint i = 0;i < bankAddresses.length;i++) 
            { 
                if(bankAddresses[i] == _ethAddress)
                {
                    banks[_ethAddress].kycPermission = _kycPermission;
                  
                    return 1;
                }
            
            }
            return 0;
    }
    
     /**
     * Check Validity of the  bank 
     * @param  {address} _ethAddress Address of the bank
     * @return {uint8}  0 indicates failure, 1 indicates success
     */
     function isValidBank(address _ethAddress) isAdmin public returns(uint8) {
        
         for(uint i = 0;i < bankAddresses.length;i++) 
            { 
                if(bankAddresses[i] == _ethAddress && banks[_ethAddress].report >  bankAddresses.length / 3)
                {
                    banks[_ethAddress].kycPermission = false;
                    
                    return 0;
                }
            
            }
        
        
        return 1;
    }

    
   
    
    

// if you are using string, you can use the following function to compare two strings
// function to compare two string value
// This is an internal fucntion to compare string values
// @Params - String a and String b are passed as Parameters
// @return - This function returns true if strings are matched and false if the strings are not matching
    function stringsEquals(string storage _a, string memory _b) internal view returns (bool) {
        bytes storage a = bytes(_a);
        bytes memory b = bytes(_b); 
        if (a.length != b.length)
            return false;
        // @todo unroll this loop
        for (uint i = 0; i < a.length; i ++)
        {
            if (a[i] != b[i])
                return false;
        }
        return true;
    }

}
