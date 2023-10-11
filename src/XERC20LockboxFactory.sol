// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {TransparentUpgradeableProxy} from "oz-regular/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";
import {IXERC20Factory} from "@xerc20/interfaces/IXERC20Factory.sol";
import {XERC20Lockbox} from "@xerc20/contracts/XERC20Lockbox.sol";
import {CREATE3} from "solmate/utils/CREATE3.sol";
import {IXERC20LockboxFactory} from "./interfaces/IXERC20LockboxFactory.sol";

contract XERC20LockboxFactory is IXERC20LockboxFactory {
    IXERC20Factory public immutable XERC20_FACTORY;

    constructor() {
        XERC20_FACTORY = IXERC20Factory(msg.sender);
    }

    /**
     * @notice Only factory is allowed to call deployLockbox
     */
    modifier onlyXERC20Factory() {
        if (msg.sender != address(XERC20_FACTORY)) revert XERC20LockboxFactory_NotXERC20Factory();
        _;
    }

    /**
     * @notice Deploys an XERC20Lockbox contract using CREATE3
     *
     * @param _xerc20 The address of the xerc20 that you want to deploy a lockbox for
     * @param _baseToken The address of the base token that you want to lock
     * @param _isNative Whether or not the base token is native
     */
    function deployLockbox(address _owner, address _xerc20, address _baseToken, bool _isNative)
        external
        onlyXERC20Factory
        returns (address payable _lockbox, address _implementation)
    {
        (_lockbox, _implementation) = _deployUpgradeableLockbox(_owner, _xerc20, _baseToken, _isNative);
    }

    function _deployUpgradeableLockbox(address _owner, address _xerc20, address _baseToken, bool _isNative)
        internal
        returns (address payable _lockbox, address _implementation)
    {
        bytes32 _salt = keccak256(abi.encodePacked(_xerc20, _baseToken, msg.sender));
        bytes32 _implementationSalt = keccak256(abi.encodePacked(_salt, "implementation"));

        // deploy lockbox
        bytes memory _creation = type(XERC20Lockbox).creationCode;
        _implementation = payable(CREATE3.deploy(_implementationSalt, _creation, 0));

        // deploy proxy with create3
        _creation = type(TransparentUpgradeableProxy).creationCode;
        bytes memory _initData =
            abi.encodeWithSelector(XERC20Lockbox.initialize.selector, _xerc20, _baseToken, _isNative);
        bytes memory _bytecode = abi.encodePacked(_creation, abi.encode(_implementation, _owner, _initData));

        // set lockbox to proxy address
        _lockbox = payable(CREATE3.deploy(_salt, _bytecode, 0));
    }
}
