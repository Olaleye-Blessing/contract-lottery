// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import { Script } from "forge-std/Script.sol";
import { VRFCoordinatorV2Mock } from "@chainlink-brownie-contracts/contracts/src/v0.8/mocks/VRFCoordinatorV2Mock.sol";

abstract contract CodeConstants {
  // VRF mock values
  uint96 public constant MOCK_BASE_FEE = 0.25 ether;
  uint96 public constant MOCK_GAS_PRICE_LINK = 1e9;
  uint256 public constant ETH_SEPOLIA_CHAIN_ID = 11155111;
  uint256 public constant LOCAL_CHAIN_ID = 31337;
}

contract HelperConfig is Script, CodeConstants {
  error HelperConfig__InvalidChainID();

  struct NetworkConfig {
    uint256 entranceFee;
    uint256 interval;
    address vrfCoordinator;
    bytes32 gasLane;
    uint64 subscriptionId;
    uint32 callbackGasLimit;
  }

  NetworkConfig public localNetworkConfig;
  mapping(uint256 chainId => NetworkConfig) public networkConfigs;

  constructor() {
    networkConfigs[ETH_SEPOLIA_CHAIN_ID] = getSepoliaConfig();
  }

  function getConfigByChainId(uint256 chainId) public returns(NetworkConfig memory) {
    if(networkConfigs[chainId].vrfCoordinator != address(0)) {
      return networkConfigs[chainId];
    } else if(chainId == LOCAL_CHAIN_ID) {
      return getOrCreateAnvilEthConfig();
    } else {
      revert HelperConfig__InvalidChainID();
    }
  }

  function getOrCreateAnvilEthConfig() public returns(NetworkConfig memory) {
    // return the config if it has already been created
    if(localNetworkConfig.vrfCoordinator != address(0)) {
      return localNetworkConfig;
    }

    vm.startBroadcast();
    VRFCoordinatorV2Mock vrfCoordinatorV2Mock = new VRFCoordinatorV2Mock(MOCK_BASE_FEE, MOCK_GAS_PRICE_LINK);
    vm.stopBroadcast();

    return NetworkConfig({
      entranceFee: 0.01 ether,
      interval: 30,
      vrfCoordinator: address(vrfCoordinatorV2Mock),
      gasLane: 0x787d74caea10b2b357790d5b5247c2f63d1d91572a9846f780606e4d953677ae, // doesn't matter
      subscriptionId: 0, // fix later
      callbackGasLimit: 5000
    });
  }

  function getSepoliaConfig() public pure returns(NetworkConfig memory) {
    return NetworkConfig({
      entranceFee: 0.01 ether,
      interval: 30,
      vrfCoordinator: 0x9DdfaCa8183c41ad55329BdeeD9F6A8d53168B1B,
      gasLane: 0x787d74caea10b2b357790d5b5247c2f63d1d91572a9846f780606e4d953677ae,
      subscriptionId: 0,
      callbackGasLimit: 5000
    });
  }
}
