// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {Script, console} from "forge-std/Script.sol";
import {HelperConfig, CodeConstants} from "./HelperConfig.s.sol";
import {VRFCoordinatorV2Mock} from "@chainlink/contracts/src/v0.8/mocks/VRFCoordinatorV2Mock.sol";
import {LinkToken} from "test/mocks/LinkToken.sol";

contract CreateSubScription is Script {
  function createSubscriptionUsingConfig() public returns(uint256, address) {
    HelperConfig helperConfig = new HelperConfig();
    address vrfCoordinator = helperConfig.getConfig().vrfCoordinator;
    (uint256 subId,) = createSubscription(vrfCoordinator);

    return (subId, vrfCoordinator);
  }

  function createSubscription(address vrfCoordinator) public returns(uint256, address) {
    console.log("Creating subscription on chain ID", block.chainid);
    vm.broadcast();
    uint256 subId = VRFCoordinatorV2Mock(vrfCoordinator).createSubscription();
    vm.stopBroadcast();
    console.log("SUB ID is", subId);
    console.log("Update SUB ID in HelperConfig.s.sol");

    return (subId, vrfCoordinator);
  }

  function run() public {
    createSubscriptionUsingConfig();
  }
}

contract FundSubScription is Script, CodeConstants {
  uint96 public constant FUND_AMOUNT = 3 ether; // 3 LINK

  function fundSubscriptionUsingConfig() public {
    HelperConfig helperConfig = new HelperConfig();
    address vrfCoordinator = helperConfig.getConfig().vrfCoordinator;
    uint256 subscriptionId = helperConfig.getConfig().subscriptionId;
    address linkToken = helperConfig.getConfig().link;
    fundSubscription(vrfCoordinator, subscriptionId, linkToken);
  }

  function fundSubscription(address vrfCoordinator, uint256 subscriptionId, address linkToken) public {
    console.log("___ FUNDING SUBSCRIPTION ___", subscriptionId);
    console.log("__ USING vrfCoordinator", vrfCoordinator);
    console.log("___ ON CHAIN ID ___", block.chainid);

    vm.startBroadcast();
    if(block.chainid == LOCAL_CHAIN_ID) {
      VRFCoordinatorV2Mock(vrfCoordinator).fundSubscription(uint64(subscriptionId), FUND_AMOUNT);
    } else {
      LinkToken(linkToken).transferAndCall(vrfCoordinator, FUND_AMOUNT, abi.encode(subscriptionId));
    }
    vm.stopBroadcast();
  }

  function run() public {
    fundSubscriptionUsingConfig();
  }
}
