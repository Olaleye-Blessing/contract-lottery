// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import { VRFCoordinatorV2Interface } from "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import { VRFConsumerBaseV2 } from "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";

/**
 * @title A simple raffle contract
 * @author Olaleye Blessing
 * @notice This contract is for creating a simple raffle
 * @dev Implements Chainlink VRFv2
 */
contract Raffle is VRFConsumerBaseV2 {
    error Raffle__NotEnoughEthSent();
    error Raffle__WinnerWithrawFailed();
    error Raffle__NotOpen();

    enum RaffleState { OPEN, CALCULATING }

    uint16 private constant REQUEST_CONFIRMATIONS = 3;
    uint32 private constant NUM_OF_WORDS = 1;

    uint256 private immutable i_entranceFee;
    // @dev interval to operate the raffle draw in seconds
    uint256 private immutable i_interval;
    VRFCoordinatorV2Interface private immutable i_vrfCoordinator;
    bytes32 private immutable i_gasLane;
    uint64 private immutable i_subscriptionId;
    uint32 private immutable i_callbackGasLimit;

    uint256 private s_lastTimeStamp;
    address payable[] private s_players;
    address private s_recentWinner;
    RaffleState private s_raffleState;

    event EnteredRaffle(address indexed player);
    event WinnerPicked(address indexed player);

    constructor(
        uint256 _entranceFee,
        uint256 _interval,
        address _vrfCoordinator,
        bytes32 _gasLane,
        uint64 _subscriptionId,
        uint32 _callbackGasLimit
    ) VRFConsumerBaseV2(_vrfCoordinator) {
        i_entranceFee = _entranceFee;
        i_interval = _interval;
        i_vrfCoordinator = VRFCoordinatorV2Interface(_vrfCoordinator);
        i_gasLane = _gasLane;
        i_subscriptionId = _subscriptionId;
        i_callbackGasLimit = _callbackGasLimit;
        s_lastTimeStamp = block.timestamp;
        s_raffleState = RaffleState.OPEN;
    }

    function enterRaffle() public payable {
        if (msg.value < i_entranceFee) revert Raffle__NotEnoughEthSent();
        if(s_raffleState != RaffleState.OPEN) revert Raffle__NotOpen();

        s_players.push(payable(msg.sender));

        emit EnteredRaffle(msg.sender);
    }

    function pickWinner() public {
        if ((block.timestamp - s_lastTimeStamp) < i_interval) {
            revert();
        }
        s_raffleState = RaffleState.CALCULATING;
        uint256 requestId = i_vrfCoordinator.requestRandomWords(
            i_gasLane, i_subscriptionId, REQUEST_CONFIRMATIONS, i_callbackGasLimit, NUM_OF_WORDS
        );
    }

    function fulfillRandomWords(uint256 _requestId, uint256[] memory randomWords) internal override {
        uint256 indexOfWinner = randomWords[0] % s_players.length;
        address payable winner = s_players[indexOfWinner];
        s_recentWinner = winner;

        s_raffleState = RaffleState.OPEN;
        s_players = new address payable[](0);
        s_lastTimeStamp = block.timestamp;

        emit WinnerPicked(winner);

        (bool success, ) = winner.call{value: address(this).balance}("");
        if(!success) revert Raffle__WinnerWithrawFailed();
    }

    function getEntranceFee() public view returns (uint256) {
        return i_entranceFee;
    }
}
