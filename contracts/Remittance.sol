pragma solidity ^0.4.23;

contract Remittance {

    struct Puzzle {
      uint256 amount;
      address sender;
      address exchanger;
      bytes32 passwordHash; // exchanger + password1 + password2
    }

    mapping(bytes32 => Puzzle) puzzles;

    constructor() public {
    }
}