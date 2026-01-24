// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/ChainRegistry.sol";

contract ChainRegistryTest is Test {
    ChainRegistry public registry;
    address public user1 = address(0x1);
    address public user2 = address(0x2);

    event NameRegistered(string indexed name, address indexed owner, uint256 timestamp);
    event NameTransferred(string indexed name, address indexed from, address indexed to);
    event NameReleased(string indexed name, address indexed owner);

    function setUp() public {
        registry = new ChainRegistry();
    }

    function testRegisterName() public {
        vm.prank(user1);
        vm.expectEmit(true, true, false, false);
        emit NameRegistered("alice", user1, block.timestamp);
        registry.registerName("alice");

        assertEq(registry.getNameOwner("alice"), user1);
        assertFalse(registry.isNameAvailable("alice"));
    }

    function testCannotRegisterDuplicateName() public {
        vm.prank(user1);
        registry.registerName("alice");

        vm.prank(user2);
        vm.expectRevert(ChainRegistry.NameAlreadyRegistered.selector);
        registry.registerName("alice");
    }

    function testTransferName() public {
        vm.prank(user1);
        registry.registerName("alice");

        vm.prank(user1);
        vm.expectEmit(true, true, true, false);
        emit NameTransferred("alice", user1, user2);
        registry.transferName("alice", user2);

        assertEq(registry.getNameOwner("alice"), user2);
    }

    function testCannotTransferUnownedName() public {
        vm.prank(user1);
        registry.registerName("alice");

        vm.prank(user2);
        vm.expectRevert(ChainRegistry.NotNameOwner.selector);
        registry.transferName("alice", user2);
    }

    function testReleaseName() public {
        vm.prank(user1);
        registry.registerName("alice");

        vm.prank(user1);
        vm.expectEmit(true, true, false, false);
        emit NameReleased("alice", user1);
        registry.releaseName("alice");

        assertTrue(registry.isNameAvailable("alice"));
        assertEq(registry.getNameOwner("alice"), address(0));
    }

    function testGetOwnerNames() public {
        vm.startPrank(user1);
        registry.registerName("alice");
        registry.registerName("alice2");
        vm.stopPrank();

        string[] memory names = registry.getOwnerNames(user1);
        assertEq(names.length, 2);
    }

    function testInvalidNameLength() public {
        vm.prank(user1);
        vm.expectRevert(ChainRegistry.InvalidName.selector);
        registry.registerName("");

        vm.prank(user1);
        vm.expectRevert(ChainRegistry.InvalidName.selector);
        registry.registerName("verylongnamethatexceedsthirtytwocharacterslimit");
    }
}
