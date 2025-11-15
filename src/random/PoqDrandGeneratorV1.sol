// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "../interfaces/IPoqDrandGeneratorV1.sol";
import "../interfaces/IPoqLotteryV1.sol";

contract PoqDrandGeneratorV1 is IPoqDrandGeneratorV1, Ownable {
    using SafeERC20 for IERC20;
	// for lottery verify
    address public poqLottery;
    uint32 public randomResult;
    uint256 public latestLotteryId;

	// for drand check
	struct RandomData{
		uint256 round;
		bytes32 randomness;
		uint256 randomResult;
		uint256 timestamp;
		bool used;
	}

	mapping(uint256 => RandomData) public allRound;
	uint256 public latestRandomId;
	uint256 public addTimeGap=30 minutes;

	/**
     * @notice add Drand data
     */
	function  addRandDomData(uint256 _round,bytes32 _randomness) external onlyOwner {
		require(block.timestamp - allRound[latestRandomId].timestamp >= addTimeGap, "Too frequently");

		latestRandomId++;

		allRound[latestRandomId]=RandomData({
			round: _round,
			randomness: _randomness,
			randomResult: uint256(_randomness),
			timestamp: block.timestamp,
			used: false
		});
	}

    /**
     * @notice Constructor
     * @dev RandomNumberGenerator must be deployed before the lottery.
     */
    constructor() Ownable(msg.sender) {}

    /**
     * @notice Request randomness 
     */
    function getRandomNumber(uint256 _endTime) external override {
        require(msg.sender == poqLottery, "Only PoqLottery");
		require(allRound[latestRandomId].timestamp > _endTime, "Random result generate too early");
		require(!allRound[latestRandomId].used, "Random result has been used");

		allRound[latestRandomId].used=true;
        fulfillRandomness(allRound[latestRandomId].randomResult);
    }

    /**
     * @notice Set the address for the PoqLottery
     * @param _poqLottery: address of the  Poqlottery
     */
    function setLotteryAddress(address _poqLottery) external onlyOwner {
        poqLottery = _poqLottery;
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
     * @notice View random data 
     * @param _randomId: randomData id
     */
    function viewRandomData(uint256 _randomId) external view returns (RandomData memory) {
        return allRound[_randomId];
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
    function fulfillRandomness(uint256 randomness) internal {
        randomResult = uint32(1000000 + (randomness % 1000000));
        latestLotteryId = IPoqLotteryV1(poqLottery).viewCurrentLotteryId();
    }
}
