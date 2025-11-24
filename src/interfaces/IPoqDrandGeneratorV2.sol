// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IPoqDrandGeneratorV2 {
    /**
     * Requests randomness from a user-provided seed
     */
    function getRandomNumber(uint256 _endTime) external;

    /**
     * View latest lotteryId numbers
     */
    function viewLatestLotteryId() external view returns (uint256);

    /**
     * Views random result
     */
    function viewRandomResult() external view returns (uint32);
}
