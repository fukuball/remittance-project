pragma solidity ^0.4.23;

contract Remittance {

    uint constant ONE_YEAR_OF_BLOCKS = 365 * 86400 / 15; // 2,102,400

    struct WirePuzzle {
        // key: exchanger + password1 + password2
        address sender;
        address exchanger;
        uint256 amount;
        uint    lastBlock;
        bool    isExist;
    }

    mapping(bytes32 => WirePuzzle) wirePuzzles;

    event LogSendFundWire(bytes32 indexed passwordHash, address indexed sender, address indexed exchanger, uint256 amount, uint lastBlock);
    event LogWithdraw(address indexed sender, bytes32 indexed passwordHash);

    constructor() public {
    }

    function hashPuzzleKey(address exchanger, string password1, string password2)
        // Yes view because that would be silly to expose your passwords with a dedicated transaction.
        view public
        returns(bytes32 hash) {
        return keccak256(abi.encodePacked(this, exchanger, password1, password2));
    }

    function sendFundWire(address exchanger, string password1, string password2, uint blockDuration) payable public returns(bool isSuccess) {
        require(exchanger != address(0), "prevent exchanger address 0");
        require(bytes(password1).length > 0, "prevent empty password1 string");
        require(bytes(password2).length > 0, "prevent empty password2 string");
        require(msg.value > 0, "prevent 0 value to wire");
        require(0 < blockDuration);
        require(blockDuration <= ONE_YEAR_OF_BLOCKS);

        bytes32 passwordHash = hashPuzzleKey(exchanger, password1, password2);

        if (wirePuzzles[passwordHash].isExist) revert(); // duplicate key

        uint lastBlock = block.number + blockDuration;

        wirePuzzles[passwordHash].sender        = msg.sender;
        wirePuzzles[passwordHash].exchanger     = exchanger;
        wirePuzzles[passwordHash].amount        = msg.value;
        wirePuzzles[passwordHash].lastBlock     = lastBlock;
        wirePuzzles[passwordHash].isExist       = true;

        emit LogSendFundWire(passwordHash, msg.sender, exchanger, msg.value, lastBlock);

        return true;
    }

    function checkWire(string password1, string password2) public view returns(address sender, address exchanger, uint256 amount, uint lastBlock) {
        require(bytes(password1).length > 0, "prevent empty password1 string");
        require(bytes(password2).length > 0, "prevent empty password2 string");

        bytes32 passwordHash = hashPuzzleKey(msg.sender, password1, password2);

        require(wirePuzzles[passwordHash].isExist, "prevent not exist wire puzzle");

        return (wirePuzzles[passwordHash].sender, wirePuzzles[passwordHash].exchanger, wirePuzzles[passwordHash].amount, wirePuzzles[passwordHash].lastBlock);
    }

    function withdraw(string password1, string password2) public returns(bool isSuccess) {

        require(bytes(password1).length > 0, "prevent empty password1 string");
        require(bytes(password2).length > 0, "prevent empty password2 string");

        bytes32 passwordHash = hashPuzzleKey(msg.sender, password1, password2);

        require(wirePuzzles[passwordHash].isExist, "prevent not exist wire puzzle");
        require(block.number <= wirePuzzles[passwordHash].lastBlock);

        uint256 toWithdraw = wirePuzzles[passwordHash].amount;
        delete wirePuzzles[passwordHash];

        msg.sender.transfer(toWithdraw);
        emit LogWithdraw(msg.sender, passwordHash);
        return true;
    }
}