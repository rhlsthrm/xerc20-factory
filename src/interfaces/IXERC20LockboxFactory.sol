// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.4 <0.9.0;

interface IXERC20LockboxFactory {
  /**
   * @notice Reverts when sender is not xerc20 factory
   */
  error XERC20LockboxFactory_NotXERC20Factory();
}