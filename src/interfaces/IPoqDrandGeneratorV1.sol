// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IPoqDrandGeneratorV1 {
	/**
     * add Drand data
     */
    function addRandDomData(uint256 _round,bytes32 _randomness) external;

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
