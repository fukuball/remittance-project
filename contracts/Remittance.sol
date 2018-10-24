pragma solidity ^0.4.23;

contract Remittance {

    struct WirePuzzle {
        uint256 amount;
        address sender;
        address exchanger;
        bytes32 passwordHash; // sender + exchanger + password1 + password2
        bool    isExist;
    }

    mapping(bytes32 => WirePuzzle) wirePuzzles;

    event LogSendFundWire(address indexed sender, address indexed exchanger,  bytes32 indexed passwordHash, uint256 value);
    event LogWithdraw(address indexed sender, bytes32 indexed passwordHash);

    constructor() public {
    }

    function sendFundWire(address exchanger, string password1, string password2) payable public returns(bool isSuccess) {
        require(exchanger != address(0), "prevent exchanger address 0");
        require(bytes(password1).length > 0, "prevent empty password1 string");
        require(bytes(password2).length > 0, "prevent empty password2 string");
        require(msg.value > 0, "prevent 0 value to wire");

        bytes32 passwordHash = keccak256(exchanger, password1, password2);

        if (wirePuzzles[passwordHash].isExist) revert(); // duplicate key

        wirePuzzles[passwordHash].amount        = msg.value;
        wirePuzzles[passwordHash].sender        = msg.sender;
        wirePuzzles[passwordHash].exchanger     = exchanger;
        wirePuzzles[passwordHash].passwordHash  = passwordHash;
        wirePuzzles[passwordHash].isExist       = true;

        emit LogSendFundWire(msg.sender, exchanger, passwordHash, msg.value);

        return true;
    }

    function checkWire(string password1, string password2) public view returns(uint256 amount, address sender) {
        require(bytes(password1).length > 0, "prevent empty password1 string");
        require(bytes(password2).length > 0, "prevent empty password2 string");

        bytes32 passwordHash = keccak256(msg.sender, password1, password2);

        require(wirePuzzles[passwordHash].isExist, "prevent not exist wire puzzle");

        return (wirePuzzles[passwordHash].amount, wirePuzzles[passwordHash].sender);
    }

    function withdraw(string password1, string password2) public returns(bool isSuccess) {

        require(bytes(password1).length > 0, "prevent empty password1 string");
        require(bytes(password2).length > 0, "prevent empty password2 string");

        bytes32 passwordHash = keccak256(msg.sender, password1, password2);

        require(wirePuzzles[passwordHash].isExist, "prevent not exist wire puzzle");

        uint256 toWithdraw = wirePuzzles[passwordHash].amount;
        delete wirePuzzles[passwordHash];

        msg.sender.transfer(toWithdraw);
        emit LogWithdraw(msg.sender, passwordHash);
        return true;
    }
}