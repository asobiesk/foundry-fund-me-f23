// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Script} from "forge-std/Script.sol";
import {FundMe} from "../src/FundMe.sol";
import {HelperConfig} from "./HelperConfig.s.sol";

contract DeployFundMe is Script {
    function run() external returns (FundMe, HelperConfig) {
        HelperConfig helperConfig = new HelperConfig();
        address ethToUsdPriceFeed = helperConfig.networkActiveConfig();
        vm.startBroadcast();
        FundMe fundMe = new FundMe(ethToUsdPriceFeed);
        vm.stopBroadcast();
        return (fundMe, helperConfig);
    }
}
