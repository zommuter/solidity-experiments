// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.18;

// https://spdx.org/licenses/BUSL-1.1.html

//import "@0xsequence/create3/contracts/Create3.sol";
import "https://github.com/0xsequence/create3/blob/master/contracts/Create3.sol";

/**
  @title A contract factory based on Agustin Aguilar's CREATE3 implementation https://github.com/0xsequence/create3
  @notice The salt is re-hashed together with the sender address `msg.sender` (using `privateDeploy`), which serves
          the purpose of avoiding front-running a contract deployment to a given address. The contract accepts ETH
          payments as donations ;)
          Alternatively to `privateDeploy`, a "salt" of zero can be used (via `unsafeDeploy`) independently of `msg.sender` at your own peril.
  @author Zommuter <zommuter+eth@gmail.com> / https://twitter.com/zommuter_eth
*/
contract Create3Factory {
    // hard-coded to avoid front-runners exploiting owner = msg.sender, since this contract is to be deterministically deployed via
    // https://github.com/Arachnid/deterministic-deployment-proxy / https://blockscan.com/address/0x4e59b44847b379578588920ca78fbf26c0b4956c
    address payable constant zommuter = payable(0x4d25F3E88C10cDC001447beaEcA6e9Ee0009c060);

    event DeployedPrivate(address indexed contractAddress, address deployer, bytes32 indexed salt, bytes indexed _creationCode);
    event DeployedUnsafe(address indexed contractAddress, bytes32 indexed salt, bytes indexed _creationCode);
    event EmergencyCall(
        address indexed callee,
        bytes indexed _calldata,
        bool success,
        bytes indexed _returndata
    );
    event EmergencyDelegateCall(
        address indexed callee,
        bytes indexed _calldata,
        bool success,
        bytes indexed _returndata
    );

    /**
    @notice Creates a new contract with given `_creationCode` and `_salt`, using the sender's address in the salt to avoid front-running
            Usage is free, but a payment can be included as donation.
    @param _salt Salt of the contract creation, resulting address will be derived from this value
           only -- note the salt is salted with `msg.sender` in order to allow for front-running resistant deployment
    @param _creationCode Creation code (constructor) of the contract to be deployed, this value doesn't affect the resulting address
    @return addr of the deployed contract, reverts on error
    */
    function privateDeploy(bytes32 _salt, bytes calldata _creationCode) external payable returns (address) {
        address addr = _deploy(_salt, bytes20(msg.sender), _creationCode);
        emit DeployedPrivate(addr, msg.sender, _salt, _creationCode);
        return addr;
    }

    function _deploy(bytes32 _salt, bytes20 _salter, bytes calldata _creationCode) internal returns (address) {
        zommuter.transfer(address(this).balance);
        _salt = keccak256(bytes.concat(_salt, _salter));
        return Create3.create3(_salt, _creationCode);
    }

    /**
    @notice Generates the address from `_salt`, using the sender's address in the salt to avoid front-running
    @param _salt Salt of the contract creation, resulting address will be derived from this value
           only -- note the salt is salted with `msg.sender` in order to allow for front-running resistant deployment
    @return addr of the deployed contract, reverts on error
    */
    function privateAddressOf(bytes32 _salt) external view returns (address) {
        return addressOf(_salt, msg.sender);
    }

    /**
    @notice Generates the address from `_salt`, using the sender's address in the salt to avoid front-running
    @param _salt Salt of the contract creation, resulting address will be derived from this value
           only -- note the salt is salted with `_sender` in order to allow for front-running resistant deployment
    @return addr of the deployed contract, reverts on error
    */
    function addressOf(bytes32 _salt, address _sender) public view returns (address) {
        _salt = keccak256(bytes.concat(_salt, bytes20(_sender)));
        return Create3.addressOf(_salt);
    }

    error UnsafeDeployRequiresOneWeiAtLeast();
    /**
    @notice Creates a new contract with given `_creationCode` and `_salt`, using the 0x00..00 address
            in the salt to avoid collisions with `privateDeploy`, but using _this_ function is entirely
            front-runable, so use it at your own peril! In order to make sure you understood this you
            _must_ pay at least one wei more than `_salt` as symbolic token, though donations are welcome.
    @param _salt Salt of the contract creation, resulting address will be derived from this value
           only -- note the salt is salted with `bytes20(0)` in order to prevent front-running a `privateDeploy` call.
    @param _creationCode Creation code (constructor) of the contract to be deployed, this value doesn't affect the resulting address
    @return addr of the deployed contract, reverts on error
    */
   function unsafeDeploy(bytes32 _salt, bytes calldata _creationCode) external payable returns (address) {
        if(msg.value <  uint256(_salt))
            revert UnsafeDeployRequiresOneWeiAtLeast();
        address addr = _deploy(_salt, bytes20(0), _creationCode);
        emit DeployedUnsafe(addr, _salt, _creationCode);
        return addr;
   }

    /**
    @notice Generates the address from `_salt`, using the 0x00..00 address in the salt to avoid front-running
    @param _salt Salt of the contract creation, resulting address will be derived from this value
            only -- note the salt is salted with 0x00..00 in order to protect `privateDeploy` from front-running
            while this version is really unsafe against that!
    @return addr of the deployed contract, reverts on error
    */
    function unsafeAddressOf(bytes32 _salt) external view returns (address) {
        return addressOf(_salt, address(0));
    }

    // last resorts if someone sent e.g. an ERC-20 token or NFT...
    function _call(address addr, bytes calldata _calldata) external returns (bool, bytes memory) {
        require(msg.sender == zommuter);
        (bool success, bytes memory result) = addr.call(_calldata);
        emit EmergencyCall(addr, _calldata, success, result);
        return (success, result);
    }

    // yup, this can be used to `selfdestruct` this contract by accident or purpose
    function _delegatecall(address addr, bytes calldata _calldata) external returns (bool, bytes memory) {
        require(msg.sender == zommuter);
        (bool success, bytes memory result) = addr.delegatecall(_calldata);
        emit EmergencyDelegateCall(addr, _calldata, success, result);
        return (success, result);
    }
}