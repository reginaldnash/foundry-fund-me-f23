//SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;
//20.12 Finished wwhen started testing I_owner

import {Test, console} from "forge-std/Test.sol";
import {FundMe} from "../../src/FundMe.sol";
import {DeployFundMe} from "../../script/DeployFundMe.s.sol";

contract FundMeTest is Test {
    FundMe fundMe;
    address OWNER = address(this);
    address USER = makeAddr("user");
    uint256 STARTING_BALANCE = 1000 ether;
    uint256 constant SEND_VALUE = 0.1 ether;

    function setUp() external {
        // fundMe = new FundMe(0x694AA1769357215DE4FAC081bf1f309aDC325306);
        DeployFundMe deployFundMe = new DeployFundMe();
        vm.deal(USER, STARTING_BALANCE); // Give USER 1000 ether

        fundMe = deployFundMe.run();
    }

    function testMinimimumDollarISFive() public {
        assertEq(fundMe.MINIMUM_USD(), 5e18);
    }

    function testOwnerIsMsgSender() public {
        assertEq(fundMe.getOwner(), msg.sender);
        console.log(fundMe.getOwner());
        console.log(address(this));
    }

    function testPriceFeedVerisonIsAccurate() public {
        uint256 version = fundMe.getVersion();
        assertEq(version, 4);
        console.log(version);
    }

    // function testFundingContractWorks() public {
    //     fundMe.fund{value: 10e18}();
    //     assertEq(fundMe.addressToAmountFunded(address(this)), 10e18);
    //     console.log(address(this).balance);
    // }

    function testFundFailsWithoutEnoughEth() public {
        // vm.expectRevert(bytes("You need to spend more ETH!"));
        // (bool revertsAsEcpected, false) = fundMe.fund{value: 0}();
        // assertTrue(
        //     revertsAsEcpected,
        //     "expectRevert: You need to spend more ETH!"
        // );
        vm.expectRevert();
        fundMe.fund{value: 0}();
    }

    function testFundUpdatesFundendDataStructure() public {
        vm.prank(USER); // The next Tx will be sent by USER
        fundMe.fund{value: SEND_VALUE}();
        uint256 amountFunded = fundMe.getAddressToAmountFunded(USER);
        assertEq(amountFunded, SEND_VALUE);
        console.log(amountFunded);
        console.log(USER.balance);
    }

    function testAddsFunderToArrayOdFunders() public {
        vm.prank(USER); // The next Tx will be sent by USER
        fundMe.fund{value: SEND_VALUE}();
        address funder = fundMe.getFunders(0);
        assertEq(funder, USER);
    }

    modifier Funded() {
        vm.prank(USER); // The next Tx will be sent by USER
        fundMe.fund{value: SEND_VALUE}();
        _;
    }

    function testOnlyOwnerCanWithdraw() public Funded {
        vm.prank(USER);
        vm.expectRevert();
        fundMe.withdraw();
    }

    function testWithdrawWithASingleFunder() public Funded {
        // Arrange - arrange test
        uint256 startingOwnerBalance = fundMe.getOwner().balance;
        uint256 staringFundMeBalance = address(fundMe).balance;

        // Act - action i want to test
        vm.prank(fundMe.getOwner());
        fundMe.withdraw();
        // Assert - assert the result of the action
        uint256 endingOwnerBalance = fundMe.getOwner().balance;
        uint256 endingFundMeBalance = address(fundMe).balance;
        assertEq(
            endingOwnerBalance,
            startingOwnerBalance + staringFundMeBalance
        );
        assertEq(endingFundMeBalance, 0);
    }

    function testWithDrawWithMultipleFunders() public Funded {
        uint160 numberOfFunders = 10;
        uint160 startingFunderIndex = 1;
        for (
            uint160 funderIndex = startingFunderIndex;
            funderIndex < numberOfFunders;
            funderIndex++
        ) {
            hoax(address(funderIndex), SEND_VALUE); // if I want to use numbers to generate addresses those numbers need to be uint160
            fundMe.fund{value: SEND_VALUE}();
        }
        uint256 startingOwnerBalance = fundMe.getOwner().balance;
        uint256 staringFundMeBalance = address(fundMe).balance;

        vm.startPrank(fundMe.getOwner());
        fundMe.withdraw();
        vm.stopPrank();

        // Assert - assert the result of the action

        assert(address(fundMe).balance == 0);
        assert(
            startingOwnerBalance + staringFundMeBalance ==
                fundMe.getOwner().balance
        );
    }

    function testWithDrawWithMultipleFundersCheaper() public Funded {
        uint160 numberOfFunders = 10;
        uint160 startingFunderIndex = 1;
        for (
            uint160 funderIndex = startingFunderIndex;
            funderIndex < numberOfFunders;
            funderIndex++
        ) {
            hoax(address(funderIndex), SEND_VALUE); // if I want to use numbers to generate addresses those numbers need to be uint160
            fundMe.fund{value: SEND_VALUE}();
        }
        uint256 startingOwnerBalance = fundMe.getOwner().balance;
        uint256 staringFundMeBalance = address(fundMe).balance;

        vm.startPrank(fundMe.getOwner());
        fundMe.cheaperWithdraw();
        vm.stopPrank();

        // Assert - assert the result of the action

        assert(address(fundMe).balance == 0);
        assert(
            startingOwnerBalance + staringFundMeBalance ==
                fundMe.getOwner().balance
        );
    }
}
