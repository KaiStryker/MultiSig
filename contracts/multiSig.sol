// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.7.5;
pragma abicoder v2;


contract MultisigWallet{


mapping(address => mapping(uint => bool)) confirmations;
mapping(address => mapping(uint => bool)) executiveSignatures;
mapping(address => bool) isOwner;
mapping(address => uint) balance;
address payable [] public owners;
uint private required;

Transaction[] private transactionLog;
ExecutiveOrders[] private ExecutiveLog;

bytes32 private _Secretcode;

struct Transaction {
        address from;
        address payable to;
        uint amount;
        uint txId;
        uint approvals;
        bool executed;
    }

struct ExecutiveOrders {
        string typeofChange;
        address from;
        uint txId;
        uint approvals;
        bool executed;
    }

    event DepositDone(address from, uint amount);
    event TransactionCreated(address from, address to, uint amount, uint transactionId);
    event ExecTransactionCreated(address from, string TypeofChange, uint transactionId);
    event TransactionCompleted(address from, address to, uint amount, uint transactionId);
    event TransactionSigned(address from, uint transactionId, uint approvals);
    event ExecutiveOrderSigned(address from, string TypeofChange, uint transactionId, uint approvals);
    event OwnerAdded(address NewOwner);
    event OwnerRemoved(address OldOwner);
    event RequirementChanged(uint NewRequirement);

constructor(address payable [] memory _owners, uint _required, string memory secretPhrase) {

     require(owners.length >= _required);

     _Secretcode = keccak256(bytes(secretPhrase));
     owners = _owners;
     required = _required;

     for(uint i=0; i<owners.length; i++){
         isOwner[owners[i]] = true;
         }


    }

modifier onlyOwners {

       bool owner = false;
       for(uint i=0; i<owners.length; i++){
           if (owners[i] == msg.sender){
               owner = true;
               break;
           }

       }

       require (owner == true, "not owner");
        _;
    }

modifier ownerDoesNotExist(address owner) {
        require(isOwner[owner] == false);
        _;
    }

modifier ownerExists(address owner) {
        require(isOwner[owner] == true);
        _;
    }

function getOwners() public view returns (address payable[] memory){

    return owners;

    }

function getRequired() public view onlyOwners returns (uint){

    return required;

    }

function changeRequiredRequest(uint _required) public onlyOwners returns (uint txId){

        ExecutiveLog.push(ExecutiveOrders("changeRequiredRequest",msg.sender,ExecutiveLog.length, 1,false));

        executiveSignatures[msg.sender][ExecutiveLog.length] = true;

        uint txID = ExecutiveLog.length;

            if (ExecutiveLog[txID].approvals >= required){

                changeRequired(_required);
                ExecutiveLog[txID].executed = true;

            }
        emit ExecTransactionCreated(msg.sender, "changeRequiredRequest", ExecutiveLog.length);

        return ExecutiveLog.length;

        }

function changeRequired (uint _required) internal onlyOwners returns (uint){

        required = _required;

        emit RequirementChanged(_required);
        return required;

        }

function addOwnerRequest(address payable _newOwner) public onlyOwners ownerDoesNotExist(_newOwner) returns (uint txId){

        ExecutiveLog.push(ExecutiveOrders("addOwnerRequest",msg.sender,ExecutiveLog.length, 1,false));

        executiveSignatures[msg.sender][ExecutiveLog.length] = true;

        uint txID = ExecutiveLog.length;

            if (ExecutiveLog[txID].approvals >= required){

                addOwner(_newOwner);
                ExecutiveLog[txID].executed = true;

            }
        emit ExecTransactionCreated(msg.sender, "addOwnerRequest", ExecutiveLog.length);

        return ExecutiveLog.length;

        }

function addOwner(address payable _owner) internal onlyOwners ownerDoesNotExist(_owner) {

        owners.push(_owner);
        isOwner[_owner] = true;
        emit OwnerAdded(_owner);
        }

function removeOwnerRequest(address _oldOwner) public onlyOwners ownerExists(_oldOwner) returns (uint txId){

        ExecutiveLog.push(ExecutiveOrders("removeOwnerRequest",msg.sender,ExecutiveLog.length, 1,false));

        executiveSignatures[msg.sender][ExecutiveLog.length] = true;

        uint txID = ExecutiveLog.length;

            if (ExecutiveLog[txID].approvals >= required){

                removeOwner(_oldOwner);
                ExecutiveLog[txID].executed = true;

            }

        emit ExecTransactionCreated(msg.sender, "removeOwnerRequest", ExecutiveLog.length);
        emit ExecutiveOrderSigned(msg.sender, "removeOwnerRequest", ExecutiveLog.length, ExecutiveLog[ExecutiveLog.length].approvals);

        return ExecutiveLog.length;

}

function removeOwner(address _owner) internal onlyOwners ownerExists(_owner) {

        for(uint i=0; i<owners.length; i++){
               if (owners[i] == _owner){
               owners[i] = owners[owners.length - 1];
               break;
                }
            owners.pop();
            if (required > owners.length){
                changeRequired(owners.length);
                 }
            }
         isOwner[_owner] = false;
         emit OwnerRemoved(_owner);
    }

function deposit() public payable returns (uint) {

     balance[msg.sender] += msg.value;
     emit DepositDone (msg.sender, msg.value);
     return balance[msg.sender];

    }

function getBalance (address _address) public view returns (uint){

    return balance[_address];

    }

function getTxs() public view returns (Transaction[] memory ){

    return transactionLog;

    }

function getExecutiveTxs() public view returns (ExecutiveOrders[] memory ){

    return ExecutiveLog;

    }

function getTransaction(uint txid) public view returns (address, address, uint,uint, bool){

    return (transactionLog[txid].from, transactionLog[txid].to, transactionLog[txid].amount, transactionLog[txid].approvals, transactionLog[txid].executed);

    }

function createTransaction(address payable to, uint value) public payable {

         require(msg.sender.balance >= value);
         require(msg.sender != to);

         addTransaction(msg.sender, to, value);

    }

function addTransaction(address _from, address payable _to, uint _amount) internal {

        transactionLog.push(Transaction(_from, _to, _amount, transactionLog.length, 0,false)
        );

        confirmations[_from][transactionLog.length] = true;

        emit TransactionCreated(msg.sender,_to, _amount, transactionLog.length);

    }

function signTrans(uint txid) public onlyOwners{

        require(confirmations[msg.sender][txid] == false);
        require(transactionLog[txid].executed == false);

        confirmations[msg.sender][txid] = true;
        transactionLog[txid].approvals++;

        emit TransactionSigned(msg.sender, txid, transactionLog[txid].approvals);

        if (transactionLog[txid].approvals >= required){

           balance[msg.sender] -= transactionLog[txid].amount;
           transactionLog[txid].to.transfer(transactionLog[txid].amount);
           transactionLog[txid].executed = true;

        emit TransactionCompleted(msg.sender, transactionLog[txid].to, transactionLog[txid].amount, transactionLog[txid].txId);

        }
    }

function checkifConfirmed(uint txid) public view returns (bool){

         return confirmations[msg.sender][txid];
    }

function executeTx(address payable _to, uint _amount, uint _txid) internal returns (uint _balance){

        require(balance[msg.sender] >= _amount, "Balance not sufficient");
        require(transactionLog[_txid].executed == false);

        if (transactionLog[_txid].approvals >= required){

           balance[msg.sender] -= _amount;
           transactionLog[_txid].to.transfer(_amount);
           transactionLog[_txid].executed = true;

        emit TransactionCompleted(msg.sender, _to, _amount, _txid);

        uint balance_ = balance[msg.sender];
        return balance_;
        }


    }

function signExecutiveOrder(uint txid) public onlyOwners{

        require(executiveSignatures[msg.sender][txid] == false);
        require(ExecutiveLog[txid].executed == false);

        executiveSignatures[msg.sender][txid] = true;
        ExecutiveLog[txid].approvals++;

        emit ExecutiveOrderSigned(msg.sender, ExecutiveLog[txid].typeofChange, txid, ExecutiveLog[txid].approvals);

    }

function lastResort(string memory secretPhrase) public onlyOwners{
        
        require(_Secretcode == keccak256(bytes(secretPhrase)));

        for(uint i=0; i<owners.length; i++){

        if (msg.sender != owners[i]){
        uint oldBalance = balance[owners[i]];
        owners[i].transfer(oldBalance);
        balance[owners[i]] = 0;
            }
        }

        require (balance[msg.sender] == address(this).balance);
        selfdestruct(msg.sender);
    }
}
