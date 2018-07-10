pragma solidity ^0.4.17;

//ToDo: make authorzied/any user to make transfer
//ToDo: check transfer from this

import "./VXR.sol";

// library SafeMath {
//     function add(uint a, uint b) internal pure returns (uint c) {
//         c = a + b;
//         require(c >= a);
//     }
//     function sub(uint a, uint b) internal pure returns (uint c) {
//         require(b <= a);
//         c = a - b;
//     }
//     function mul(uint a, uint b) internal pure returns (uint c) {
//         c = a * b;
//         require(a == 0 || c / a == b);
//     }
//     function div(uint a, uint b) internal pure returns (uint c) {
//         require(b > 0);
//         c = a / b;
//     }
// }

contract VXRDistribution{
    using SafeMath for uint;
    VXR public token;
    address public owner;
    //check this counter to know how many recipients got the Airdrop
    uint256 public counter;
    //period 1: x+1months
    //period 2: x+3months
    //period 3: x+6months
    mapping(address => mapping(uint => uint)) CustodyAccount;
    mapping (address => bool) admins;

    uint public icoEndTime;
    uint public unlockDate1;
    uint public unlockDate2;
    uint public unlockDate3;
    uint public Day = 24*60*60;

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    modifier onlyAdmin {
        require(msg.sender == owner || admins[msg.sender]);
        _;
    }

    event TokenTransferToCustody(address userAddress, uint period, uint value);
    event TokenClaimed(address userAddress, uint claimedValu, uint claimedDate);


    function VXRDistribution(address _token, uint _icoEndTime, uint _waitPeriod) public{
        require(_token != address(0));
        token = VXR(_token);
        owner = msg.sender;
        icoEndTime = _icoEndTime;
        unlockDate1 = icoEndTime + _waitPeriod*Day;
        unlockDate2 = unlockDate1 + 3*30*Day; //add 3 months
        unlockDate3 = unlockDate2 + 3*30*Day; //add another 3 months
    }

    function setAdmin(address _admin, bool isAdmin) public onlyOwner {
        admins[_admin] = isAdmin;
    }

    //Airdrop to custody account
    function airdropToken(address[] recipients, uint value) public onlyAdmin {
        require(recipients.length>0);

        counter = 0;

        for(uint i=0; i < recipients.length; i++){
            tokenTransfer(recipients[i], 1, value);
            counter++;
        }
    }

    //Normal batch transfer to custody account
    function batchTransfer(address[] recipients, uint period, uint[] value) public onlyAdmin {
        require(recipients.length>0);

        for(uint i=0; i < recipients.length; i++){
            tokenTransfer(recipients[i], period, value[i]);
        }
    }

    //Normal transfer to custody account    
    function tokenTransfer(address recipient, uint period, uint value) public onlyAdmin {

        CustodyAccount[recipient][period] = CustodyAccount[recipient][period].add(value);

        TokenTransferToCustody(recipient, period, value);
    }

    //Batch VIP transfer to custody account 
    function batchTransferVIP(address[] recipients, uint[] value) public onlyAdmin {
        require(recipients.length>0);

        for(uint i=0; i < recipients.length; i++){
            tokenTransferVIP(recipients[i], value[i]);   
        }
    }

    //VIP transfer to custody account 
    function tokenTransferVIP(address recipient, uint value) public onlyAdmin {
        uint amount1 = value.div(3);
        uint amount2 = amount1;
        uint amount3 = value.sub(amount1).sub(amount2);

        tokenTransfer(recipient, 1, amount1);
        tokenTransfer(recipient, 2, amount2);
        tokenTransfer(recipient, 3, amount3);   

        //3 means this is vip transfer
        TokenTransferToCustody(recipient, 3, value);
    }

    //Any one can view their balance in each of their custody account
    function getBalance(address userWallet, uint period) public constant returns(uint balance){
        return CustodyAccount[userWallet][period];
    }
  
    //Claim token to user account
    function claimToken(uint period) public returns (bool success) {
        if(period == 1) {
            require(now > unlockDate1);
        } else if(period == 2) {
            require(now > unlockDate2);
        } else if(period == 3) {
            require(now > unlockDate3);
        } else {
            return false;
        }

        require(CustodyAccount[msg.sender][period] > 0);

        token.transfer(msg.sender, CustodyAccount[msg.sender][period]);
        CustodyAccount[msg.sender][period] = 0;

        TokenClaimed(msg.sender, CustodyAccount[msg.sender][period], now);
        return true;
    }

}