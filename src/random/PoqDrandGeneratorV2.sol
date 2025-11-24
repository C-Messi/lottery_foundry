// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "../interfaces/IPoqDrandGeneratorV2.sol";
import "../interfaces/IPoqLotteryV1.sol";
import "../interfaces/IDrandBeacon.sol";

contract PoqDrandGeneratorV2 is IPoqDrandGeneratorV2, Ownable {
    using SafeERC20 for IERC20;

	// for lottery verify
    address public poqLottery;
	address public drandBeacon;
    uint32 public randomResult;
    uint256 public latestLotteryId;
	uint256 public requestTimeStamp;

    /**
     * @notice Constructor
     * @dev RandomNumberGenerator must be deployed before the lottery.
     */
    constructor() Ownable(msg.sender) {
	}

    /**
     * @notice Request randomness 
     */
    function getRandomNumber(uint256 _endTime) external override {
        require(msg.sender == poqLottery, "Only PoqLottery");

		requestTimeStamp = _endTime;
    }

    /**
     * @notice Set the address for the PoqLottery
     * @param _poqLottery: address of the  Poqlottery
     */
    function setLotteryAddress(address _poqLottery) external onlyOwner {
        poqLottery = _poqLottery;
    }

	/**
     * @notice Set the address for the drandBeacon
     * @param _drandBeacon: address of the  drandBeacon
     */
    function setDrandBeaconAddress(address _drandBeacon) external onlyOwner {
        drandBeacon = _drandBeacon;
    }

    /**
     * @notice It allows the admin to withdraw tokens sent to the contract
     * @param _tokenAddress: the address of the token to withdraw
     * @param _tokenAmount: the number of token amount to withdraw
     * @dev Only callable by owner.
     */
    function withdrawTokens(address _tokenAddress, uint256 _tokenAmount) external onlyOwner {
        IERC20(_tokenAddress).safeTransfer(address(msg.sender), _tokenAmount);
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
     * @notice transition result and set flag
     */
    function fulfillRandomness(uint256 round, uint256[2] memory signature) external {
		// make sure it is the round closest to the end time
		uint256 delta = requestTimeStamp - 1727521075;
		uint256 _round = (delta / 3) + ((delta % 3) > 0 ? 1 : 0);
		require(round == _round, "No correct round");

		// check validity
		IDrandBeacon(drandBeacon).verifyBeaconRound(round, signature);

		// set result
		uint256 randomness = uint256(keccak256(abi.encode(signature)));
        randomResult = uint32(1000000 + (randomness % 1000000));
        latestLotteryId = IPoqLotteryV1(poqLottery).viewCurrentLotteryId();
    }
}
