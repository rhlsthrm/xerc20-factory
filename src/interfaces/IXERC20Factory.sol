// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.19;

import {IXERC20Factory as _IXERC20Factory} from "@xerc20/interfaces/IXERC20Factory.sol";

interface IXERC20Factory is _IXERC20Factory {
    /**
     * @notice Emitted when a new XERC20 implementation deployed
     */

    event XERC20ImplementationDeployed(address indexed _xerc20);

    /**
     * @notice Emitted when a new XERC20Lockbox implementation deployed
     */

    event LockboxImplementationDeployed(address indexed _lockbox);
}
