// SPDX-License-Identifier: MIT
pragma solidity ^0.8;

/// @title IDrandBeacon
/// @notice Contract containing immutable information about a drand beacon.
interface IDrandBeacon {
    /// @notice Verify the signature produced by a drand beacon round against
    ///     the known public key. Should revert if the signature is invalid.
    /// @param round The beacon round to verify
    /// @param signature The signature to verify
    function verifyBeaconRound(
        uint256 round,
        uint256[2] memory signature
    ) external;
}
