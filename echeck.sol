pragma solidity ^0.5.12;
/* 
post-dated eCheck contract 
v0.1 (20191204)
by gustav0x 
*/ 
contract eCheckContrac{
    address owner;
    uint entityID;
    uint memberID;
    uint256 counterID;
 
    struct entity {
        uint entityID;
        uint entityCode;
        uint state;
    }
    mapping(address => entity) mapEntity;
 
    struct member{
        uint    memberID;
        address entityAddress;
        uint    state;
    }   
    mapping(address => member) mapMember;

     struct eCheck{
        uint256 ecID;
        uint    ts2PayEnabled;
        address entityAddress; // entidad pagadora
        address ecCreator;
        address firstReceiver;
        mapping (address => uint) balance;
    } 
    mapping(uint256 => eCheck) mapEC;
    mapping (address => mapping( uint256 => uint)) mapReceiverBalance;
    mapping (address => mapping( uint256 => bool)) mapReceiverEnabledWithdraw;
    
    constructor() public  {
            owner = msg.sender;
    } 
    
    //add entity
    function addEntity(address _address, uint _entityCode) public {
        require(msg.sender == owner);
        entityID++;
        mapEntity[_address] = entity(entityID, _entityCode,1);
    }
    //disable entity
    function disableEntity(address _entityAddress) public {
        require(msg.sender == owner);    
        require(mapEntity[_entityAddress].state == 1);
        mapEntity[_entityAddress].state = 0;
    }
    //enable entity
    function enableEntity(address _entityAddress) public {
        require(msg.sender == owner);    
        require(mapEntity[_entityAddress].state == 0);
        mapEntity[_entityAddress].state = 1;
    }
    
    //add member by entity
    function addMenber(address _memberAddress) public {
        //enabled entity
        require(mapEntity[msg.sender].state == 1);
        // member only support one entity
        require(mapMember[_memberAddress].memberID == 0); 
        memberID++;
        mapMember[_memberAddress] = member(memberID, /* entity address */ msg.sender, 1);
    }
    //disable member
    function disableMember(address _memberAddress) public {
        require(mapMember[_memberAddress].entityAddress == msg.sender, "ERROR: not valid entity");
        require(mapMember[_memberAddress].state == 1);
        mapMember[_memberAddress].state = 0;
    }
    //enable member
    function enableMember(address _memberAddress) public {
        require(mapMember[_memberAddress].entityAddress == msg.sender, "ERROR: not valid entity");
        require(mapMember[_memberAddress].state == 0);
        mapMember[_memberAddress].state = 1;
    }
    
    //Create echeck
    function createEc(uint _ts2Pay, uint _tokens, address _receiver) public {
        //member & entity enabled?
        require(mapMember[msg.sender].state == 1); 
        require(mapEntity[mapMember[msg.sender].entityAddress].state == 1);
        //valid value?
        require(_tokens>0);
        require(_tokens<1000000); // max value support
        //not exists echeck
        require(mapEC[counterID].ecID == 0);
        //create echeck
        counterID++;
        mapEC[counterID] = eCheck(counterID, _ts2Pay, mapMember[msg.sender].entityAddress ,msg.sender, _receiver);
        mapEC[counterID].balance[_receiver] = _tokens;
        mapReceiverBalance[_receiver][counterID] = _tokens;
    }
    
    //transfer (allow partial transfer)
    function transferEC(uint256 _ecID, uint _tokens, address _receiver) public {
        require(_tokens > 0);
        //sender secure subtraction
        require(mapEC[_ecID].balance[msg.sender] >= _tokens,       "ERROR: insufficient funds");
        uint256 newSubBalance = mapEC[_ecID].balance[msg.sender] - _tokens;
        mapEC[_ecID].balance[msg.sender] = newSubBalance; 
        mapReceiverBalance[msg.sender][_ecID]   = newSubBalance;
        //receiver secure addition
        uint256 newAddBalance =  mapEC[_ecID].balance[_receiver] + _tokens;
        require(newAddBalance >= mapEC[_ecID].balance[_receiver],  "ERROR: addition ovwerflow");
        mapEC[_ecID].balance[_receiver] = newAddBalance;
        mapReceiverBalance[_receiver][_ecID]   = newAddBalance;
    }
    
    //allow entity withdraw payday
    function allowWithdraw(uint _ecID) public {
        require(mapReceiverBalance[msg.sender][_ecID] > 0, "ERROR: without funds");
        mapReceiverEnabledWithdraw[msg.sender][_ecID] = true;
    }
    
    //entity withdraw to pay
    function entityWithdraw(uint _ecID, address _receiver) public {
        require(mapEC[_ecID].entityAddress == msg.sender,             "ERROR: not valid entity");
        require(mapReceiverBalance[_receiver][_ecID] > 0,             "ERROR: without funds");
        require(mapReceiverEnabledWithdraw[_receiver][_ecID] == true, "ERROR: balance withdraw not allowed");
        mapEC[_ecID].balance[_receiver]       = 0;
        mapReceiverBalance[_receiver][_ecID]  = 0;
    }
}
