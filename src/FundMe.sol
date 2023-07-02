// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import {PriceConverter} from "./PriceConverter.sol";

error FundMe__NotOwner();
error FundMe__NoMoneyToReclaim();

contract FundMe {
    using PriceConverter for uint256;

    address[] private s_funders;
    mapping(address funder => uint256 amountFunded)
        private s_addressToAmountFunded;
    address private immutable i_owner;
    uint256 public constant MINIMUM_USD = 5e18;

    AggregatorV3Interface private immutable s_priceFeed;

    constructor(address _priceFeedAddress) {
        i_owner = msg.sender;
        s_priceFeed = AggregatorV3Interface(_priceFeedAddress);
    }

    function fund() public payable {
        require(
            msg.value.getConversionRate(s_priceFeed) >= MINIMUM_USD,
            "Didn't send enough ETH!"
        );
        s_funders.push(msg.sender);
        s_addressToAmountFunded[msg.sender] += msg.value;
    }

    function withdraw() public onlyOwner {
        cleanupFunders();
        payable(msg.sender).transfer(address(this).balance);
    }

    function reclaimFunds() public {
        uint256 amountFunded = s_addressToAmountFunded[msg.sender];
        if (amountFunded == 0) {
            revert FundMe__NoMoneyToReclaim();
        }
        s_addressToAmountFunded[msg.sender] = 0;
        payable(msg.sender).transfer(amountFunded);
    }

    function cleanupFunders() internal {
        uint256 fundersLength = s_funders.length;
        for (uint256 i = 0; i < fundersLength; ++i) {
            address funder = s_funders[i];
            s_addressToAmountFunded[funder] = 0;
        }
        s_funders = new address[](0);
    }

    modifier onlyOwner() {
        if (msg.sender != i_owner) {
            revert FundMe__NotOwner();
        }
        _;
    }

    receive() external payable {
        fund();
    }

    fallback() external payable {
        fund();
    }

    /* View / Pure Functions */

    function getAddressToAmountFunded(
        address fundingAddress
    ) external view returns (uint256) {
        return s_addressToAmountFunded[fundingAddress];
    }

    function getFunder(uint256 index) external view returns (address) {
        return s_funders[index];
    }

    function getOwner() external view returns (address) {
        return i_owner;
    }

    function getVersion() public view returns (uint256) {
        return s_priceFeed.version();
    }
}
