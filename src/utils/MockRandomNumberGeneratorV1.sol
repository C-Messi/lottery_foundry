//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "../interfaces/IPoqDrandGeneratorV2.sol";
import "../interfaces/IPoqLottery.sol";

contract MockRandomNumberGeneratorV1 is IPoqDrandGeneratorV2, Ownable {
    address public poqLottery;
    uint32 public randomResult;
    uint256 public nextRandomResult;
    uint256 public latestLotteryId;

    /**
     * @notice Constructor
     * @dev MockRandomNumberGenerator must be deployed before the lottery.
     */
    constructor() Ownable(msg.sender) {}

    /**
     * @notice Set the address for the PoqLottery
     * @param _poqLottery: address of the Poq lottery
     */
    function setLotteryAddress(address _poqLottery) external onlyOwner {
        poqLottery = _poqLottery;
    }

    /**
     * @notice Set the address for the PoqLottery
     * @param _nextRandomResult: next random result
     */
    function setNextRandomResult(uint256 _nextRandomResult) external onlyOwner {
        nextRandomResult = _nextRandomResult;
    }

    /**
     * @notice Request randomness from a user-provided seed
     */
    function getRandomNumber(uint256 _endTime) external override {
        require(msg.sender == poqLottery, "Only PoqLottery");
        fulfillRandomness(0, nextRandomResult);
		_endTime = _endTime;
    }

    /**
     * @notice Change latest lotteryId to currentLotteryId
     */
    function changeLatestLotteryId() external {
        latestLotteryId = IPoqLottery(poqLottery).viewCurrentLotteryId();
    }

    /**
     * @notice View latestLotteryId
     */
    function viewLatestLotteryId() external view override returns (uint256) {
        return latestLotteryId;
    }

    /**
     * @notice View random result
     */
    function viewRandomResult() external view override returns (uint32) {
        return randomResult;
    }

    /**
     * @notice Callback function used by ChainLink's VRF Coordinator
     */
    function fulfillRandomness(bytes32 requestId, uint256 randomness) internal {
        randomResult = uint32(1000000 + (randomness % 1000000));
		requestId=requestId;// avoid warning
		latestLotteryId = IPoqLottery(poqLottery).viewCurrentLotteryId();
    }
}
