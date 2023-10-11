// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {XERC20} from '@xerc20/contracts/XERC20.sol';
import {IXERC20Factory} from '@xerc20/interfaces/IXERC20Factory.sol';
import {TransparentUpgradeableProxy} from 'oz-regular/contracts/proxy/transparent/TransparentUpgradeableProxy.sol';
import {XERC20LockboxFactory} from './XERC20LockboxFactory.sol';
import {CREATE3} from 'solmate/utils/CREATE3.sol';

contract XERC20Factory is IXERC20Factory {
  /**
   * @notice Address of the xerc20 maps to the address of its lockbox if it has one
   */
  mapping(address => address) public lockboxRegistry;

  XERC20LockboxFactory public lockboxFactory;

  constructor() {
    lockboxFactory = new XERC20LockboxFactory();
  }

  /**
   * @notice Deploys an ConnextXERC20 contract using CREATE3
   * @dev _limits and _minters must be the same length
   * @param _minterLimits The array of limits that you are adding (optional, can be an empty array)
   * @param _burnerLimits The array of limits that you are adding (optional, can be an empty array)
   * @param _bridges The array of bridges that you are adding (optional, can be an empty array)
   */
  function deployXERC20(
    address _owner,
    uint256[] memory _minterLimits,
    uint256[] memory _burnerLimits,
    address[] memory _bridges
  ) external returns (address _xerc20) {
    _xerc20 = _deployUpgradeableXERC20("Connext Token", "NEXT", _owner, _minterLimits, _burnerLimits, _bridges);

    emit XERC20Deployed(_xerc20);
  }

  /**
   * @notice Deploys an XERC20Lockbox contract using CREATE3
   *
   * @param _xerc20 The address of the xerc20 that you want to deploy a lockbox for
   * @param _baseToken The address of the base token that you want to lock
   * @param _isNative Whether or not the base token is native
   */

  function deployLockbox(
    address _owner,
    address _xerc20,
    address _baseToken,
    bool _isNative
  ) external returns (address payable _lockbox) {
    if (_baseToken == address(0) && !_isNative) revert IXERC20Factory_BadTokenAddress();

    if (ConnextXERC20(_xerc20).owner() != msg.sender) revert IXERC20Factory_NotOwner();
    if (lockboxRegistry[_xerc20] != address(0)) revert IXERC20Factory_LockboxAlreadyDeployed();

    address _implementation;
    (_lockbox, _implementation) = lockboxFactory.deployLockbox(_owner, _xerc20, _baseToken, _isNative);
    lockboxRegistry[_xerc20] = _lockbox;
    emit LockboxImplementationDeployed(_implementation);

    emit LockboxDeployed(_lockbox);
  }

  /**
   * @notice Deploys an ConnextXERC20 contract using CREATE3
   * @dev _limits and _minters must be the same length
   * @param _name The name of the token
   * @param _symbol The symbol of the token
   * @param _minterLimits The array of limits that you are adding (optional, can be an empty array)
   * @param _burnerLimits The array of limits that you are adding (optional, can be an empty array)
   * @param _bridges The array of burners that you are adding (optional, can be an empty array)
   */
  function _deployUpgradeableXERC20(
    string memory _name,
    string memory _symbol,
    address _owner,
    uint256[] memory _minterLimits,
    uint256[] memory _burnerLimits,
    address[] memory _bridges
  ) internal returns (address _xerc20) {
    uint256 _bridgesLength = _bridges.length;
    if (_minterLimits.length != _bridgesLength || _burnerLimits.length != _bridgesLength) {
      revert IXERC20Factory_InvalidLength();
    }
    bytes32 _salt = keccak256(abi.encodePacked(_name, _symbol, msg.sender));
    bytes32 _implementationSalt = keccak256(abi.encodePacked(_salt, "implementation"));

    // deploy implementation
    address _implementation = CREATE3.deploy(_implementationSalt, type(ConnextXERC20).creationCode, 0);
    emit XERC20ImplementationDeployed(_implementation);

    // deploy proxy with create3
    bytes memory _creation = type(TransparentUpgradeableProxy).creationCode;
    bytes memory _initData = abi.encodeWithSelector(ConnextXERC20.initialize.selector, _owner, _owner, _bridges, _minterLimits, _burnerLimits);
    bytes memory _bytecode = abi.encodePacked(_creation, abi.encode(_implementation, _owner, _initData));

    // set xerc20 to proxy address
    _xerc20 = CREATE3.deploy(_salt, _bytecode, 0);
  }
}