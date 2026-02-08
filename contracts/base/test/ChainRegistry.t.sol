// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/ChainRegistry.sol";

contract UchainregistryTest is Test {
    Uchainregistry public registry;
    
    address public owner = address(1);
    address public user1 = address(2);
    address public user2 = address(3);
    address public user3 = address(4);
    
    uint256 public constant REGISTRATION_FEE = 0.01 ether;
    uint256 public constant REGISTRATION_DURATION = 365 days;
    uint256 public constant GRACE_PERIOD = 30 days;
    
    event NameRegistered(string indexed name, address indexed owner, uint256 expiresAt);
    event NameTransferred(string indexed name, address indexed from, address indexed to);
    event NameReleased(string indexed name, address indexed owner);
    event NameRenewed(string indexed name, address indexed owner, uint256 newExpiresAt);
    event RegistrationFeeUpdated(uint256 oldFee, uint256 newFee);
    
    function setUp() public {
        vm.prank(owner);
        registry = new Uchainregistry(REGISTRATION_FEE);
        
        // Fund test users
        vm.deal(user1, 10 ether);
        vm.deal(user2, 10 ether);
        vm.deal(user3, 10 ether);
    }
    
    /*//////////////////////////////////////////////////////////////
                          DEPLOYMENT TESTS
    //////////////////////////////////////////////////////////////*/
    
    function testDeployment() public {
        assertEq(registry.registrationFee(), REGISTRATION_FEE);
        assertEq(registry.owner(), owner);
    }
    
    /*//////////////////////////////////////////////////////////////
                        REGISTRATION TESTS
    //////////////////////////////////////////////////////////////*/
    
    function testRegisterName() public {
        vm.prank(user1);
        vm.expectEmit(true, true, false, true);
        emit NameRegistered("alice", user1, block.timestamp + REGISTRATION_DURATION);
        
        registry.registerName{value: REGISTRATION_FEE}("alice");
        
        (address regOwner, uint256 registeredAt, uint256 expiresAt, bool isExpired) = 
            registry.getRegistration("alice");
        
        assertEq(regOwner, user1);
        assertEq(registeredAt, block.timestamp);
        assertEq(expiresAt, block.timestamp + REGISTRATION_DURATION);
        assertFalse(isExpired);
    }
    
    function testRegisterNameWithExcessPayment() public {
        uint256 initialBalance = user1.balance;
        
        vm.prank(user1);
        registry.registerName{value: 0.05 ether}("alice");
        
        // Should refund excess
        assertEq(user1.balance, initialBalance - REGISTRATION_FEE);
    }
    
    function testRegisterNameMinLength() public {
        vm.prank(user1);
        registry.registerName{value: REGISTRATION_FEE}("abc");
        
        assertEq(registry.getNameOwner("abc"), user1);
    }
    
    function testRegisterNameMaxLength() public {
        string memory longName = "abcdefghijklmnopqrstuvwxyz123456"; // 32 chars
        
        vm.prank(user1);
        registry.registerName{value: REGISTRATION_FEE}(longName);
        
        assertEq(registry.getNameOwner(longName), user1);
    }
    
    function testRegisterNameWithHyphens() public {
        vm.prank(user1);
        registry.registerName{value: REGISTRATION_FEE}("alice-bob");
        
        assertEq(registry.getNameOwner("alice-bob"), user1);
    }
    
    function testRegisterMultipleNames() public {
        vm.startPrank(user1);
        registry.registerName{value: REGISTRATION_FEE}("alice");
        registry.registerName{value: REGISTRATION_FEE}("bob");
        registry.registerName{value: REGISTRATION_FEE}("charlie");
        vm.stopPrank();
        
        string[] memory names = registry.getOwnerNames(user1);
        assertEq(names.length, 3);
    }
    
    function testCannotRegisterDuplicateName() public {
        vm.prank(user1);
        registry.registerName{value: REGISTRATION_FEE}("alice");
        
        vm.prank(user2);
        vm.expectRevert(Uchainregistry.NameAlreadyRegistered.selector);
        registry.registerName{value: REGISTRATION_FEE}("alice");
    }
    
    function testCannotRegisterWithInsufficientPayment() public {
        vm.prank(user1);
        vm.expectRevert(Uchainregistry.InsufficientPayment.selector);
        registry.registerName{value: 0.001 ether}("alice");
    }
    
    function testCannotRegisterTooShortName() public {
        vm.prank(user1);
        vm.expectRevert(Uchainregistry.InvalidName.selector);
        registry.registerName{value: REGISTRATION_FEE}("ab");
    }
    
    function testCannotRegisterTooLongName() public {
        string memory tooLong = "abcdefghijklmnopqrstuvwxyz1234567"; // 33 chars
        
        vm.prank(user1);
        vm.expectRevert(Uchainregistry.InvalidName.selector);
        registry.registerName{value: REGISTRATION_FEE}(tooLong);
    }
    
    function testCannotRegisterWithInvalidCharacters() public {
        vm.prank(user1);
        vm.expectRevert(Uchainregistry.InvalidName.selector);
        registry.registerName{value: REGISTRATION_FEE}("alice@bob");
    }
    
    function testCannotRegisterWithSpaces() public {
        vm.prank(user1);
        vm.expectRevert(Uchainregistry.InvalidName.selector);
        registry.registerName{value: REGISTRATION_FEE}("alice bob");
    }
    
    function testCannotRegisterWhenPaused() public {
        vm.prank(owner);
        registry.pause();
        
        vm.prank(user1);
        vm.expectRevert("Pausable: paused");
        registry.registerName{value: REGISTRATION_FEE}("alice");
    }
    
    /*//////////////////////////////////////////////////////////////
                          RENEWAL TESTS
    //////////////////////////////////////////////////////////////*/
    
    function testRenewName() public {
        vm.prank(user1);
        registry.registerName{value: REGISTRATION_FEE}("alice");
        
        (, , uint256 initialExpiry, ) = registry.getRegistration("alice");
        
        vm.prank(user1);
        vm.expectEmit(true, true, false, true);
        emit NameRenewed("alice", user1, initialExpiry + REGISTRATION_DURATION);
        
        registry.renewName{value: REGISTRATION_FEE}("alice");
        
        (, , uint256 newExpiry, ) = registry.getRegistration("alice");
        assertEq(newExpiry, initialExpiry + REGISTRATION_DURATION);
    }
    
    function testCannotRenewUnregisteredName() public {
        vm.prank(user1);
        vm.expectRevert(Uchainregistry.NameNotRegistered.selector);
        registry.renewName{value: REGISTRATION_FEE}("alice");
    }
    
    function testCannotRenewOthersName() public {
        vm.prank(user1);
        registry.registerName{value: REGISTRATION_FEE}("alice");
        
        vm.prank(user2);
        vm.expectRevert(Uchainregistry.NotNameOwner.selector);
        registry.renewName{value: REGISTRATION_FEE}("alice");
    }
    
    function testCannotRenewWithInsufficientPayment() public {
        vm.prank(user1);
        registry.registerName{value: REGISTRATION_FEE}("alice");
        
        vm.prank(user1);
        vm.expectRevert(Uchainregistry.InsufficientPayment.selector);
        registry.renewName{value: 0.001 ether}("alice");
    }
    
    /*//////////////////////////////////////////////////////////////
                          TRANSFER TESTS
    //////////////////////////////////////////////////////////////*/
    
    function testTransferName() public {
        vm.prank(user1);
        registry.registerName{value: REGISTRATION_FEE}("alice");
        
        vm.prank(user1);
        vm.expectEmit(true, true, true, false);
        emit NameTransferred("alice", user1, user2);
        
        registry.transferName("alice", user2);
        
        assertEq(registry.getNameOwner("alice"), user2);
        
        string[] memory user1Names = registry.getOwnerNames(user1);
        assertEq(user1Names.length, 0);
        
        string[] memory user2Names = registry.getOwnerNames(user2);
        assertEq(user2Names.length, 1);
        assertEq(user2Names[0], "alice");
    }
    
    function testCannotTransferToZeroAddress() public {
        vm.prank(user1);
        registry.registerName{value: REGISTRATION_FEE}("alice");
        
        vm.prank(user1);
        vm.expectRevert(Uchainregistry.InvalidAddress.selector);
        registry.transferName("alice", address(0));
    }
    
    function testCannotTransferUnregisteredName() public {
        vm.prank(user1);
        vm.expectRevert(Uchainregistry.NameNotRegistered.selector);
        registry.transferName("alice", user2);
    }
    
    function testCannotTransferOthersName() public {
        vm.prank(user1);
        registry.registerName{value: REGISTRATION_FEE}("alice");
        
        vm.prank(user2);
        vm.expectRevert(Uchainregistry.NotNameOwner.selector);
        registry.transferName("alice", user3);
    }
    
    function testCannotTransferExpiredName() public {
        vm.prank(user1);
        registry.registerName{value: REGISTRATION_FEE}("alice");
        
        // Fast forward past expiration + grace period
        vm.warp(block.timestamp + REGISTRATION_DURATION + GRACE_PERIOD + 1);
        
        vm.prank(user1);
        vm.expectRevert(Uchainregistry.NameExpired.selector);
        registry.transferName("alice", user2);
    }
    
    /*//////////////////////////////////////////////////////////////
                          RELEASE TESTS
    //////////////////////////////////////////////////////////////*/
    
    function testReleaseName() public {
        vm.prank(user1);
        registry.registerName{value: REGISTRATION_FEE}("alice");
        
        vm.prank(user1);
        vm.expectEmit(true, true, false, false);
        emit NameReleased("alice", user1);
        
        registry.releaseName("alice");
        
        assertEq(registry.getNameOwner("alice"), address(0));
        assertTrue(registry.isNameAvailable("alice"));
        
        string[] memory names = registry.getOwnerNames(user1);
        assertEq(names.length, 0);
    }
    
    function testCannotReleaseUnregisteredName() public {
        vm.prank(user1);
        vm.expectRevert(Uchainregistry.NameNotRegistered.selector);
        registry.releaseName("alice");
    }
    
    function testCannotReleaseOthersName() public {
        vm.prank(user1);
        registry.registerName{value: REGISTRATION_FEE}("alice");
        
        vm.prank(user2);
        vm.expectRevert(Uchainregistry.NotNameOwner.selector);
        registry.releaseName("alice");
    }
    
    /*//////////////////////////////////////////////////////////////
                        EXPIRATION TESTS
    //////////////////////////////////////////////////////////////*/
    
    function testNameExpirationAfterDuration() public {
        vm.prank(user1);
        registry.registerName{value: REGISTRATION_FEE}("alice");
        
        // Within grace period - still owned
        vm.warp(block.timestamp + REGISTRATION_DURATION + 1);
        assertEq(registry.getNameOwner("alice"), user1);
        assertFalse(registry.isNameAvailable("alice"));
        
        // After grace period - expired
        vm.warp(block.timestamp + GRACE_PERIOD + 1);
        assertEq(registry.getNameOwner("alice"), address(0));
        assertTrue(registry.isNameAvailable("alice"));
    }
    
    function testCanRegisterExpiredName() public {
        vm.prank(user1);
        registry.registerName{value: REGISTRATION_FEE}("alice");
        
        // Fast forward past expiration + grace period
        vm.warp(block.timestamp + REGISTRATION_DURATION + GRACE_PERIOD + 1);
        
        // User2 can now register it
        vm.prank(user2);
        registry.registerName{value: REGISTRATION_FEE}("alice");
        
        assertEq(registry.getNameOwner("alice"), user2);
    }
    
    function testGetActiveOwnerNames() public {
        vm.startPrank(user1);
        registry.registerName{value: REGISTRATION_FEE}("alice");
        registry.registerName{value: REGISTRATION_FEE}("bob");
        registry.registerName{value: REGISTRATION_FEE}("charlie");
        vm.stopPrank();
        
        // Fast forward to expire "alice"
        vm.warp(block.timestamp + REGISTRATION_DURATION + GRACE_PERIOD + 1);
        
        string[] memory activeNames = registry.getActiveOwnerNames(user1);
        assertEq(activeNames.length, 2); // bob and charlie still active
    }
    
    /*//////////////////////////////////////////////////////////////
                          VIEW FUNCTION TESTS
    //////////////////////////////////////////////////////////////*/
    
    function testIsNameAvailable() public {
        assertTrue(registry.isNameAvailable("alice"));
        
        vm.prank(user1);
        registry.registerName{value: REGISTRATION_FEE}("alice");
        
        assertFalse(registry.isNameAvailable("alice"));
    }
    
    function testGetNameOwner() public {
        assertEq(registry.getNameOwner("alice"), address(0));
        
        vm.prank(user1);
        registry.registerName{value: REGISTRATION_FEE}("alice");
        
        assertEq(registry.getNameOwner("alice"), user1);
    }
    
    function testGetRegistration() public {
        vm.prank(user1);
        registry.registerName{value: REGISTRATION_FEE}("alice");
        
        (address regOwner, uint256 registeredAt, uint256 expiresAt, bool isExpired) = 
            registry.getRegistration("alice");
        
        assertEq(regOwner, user1);
        assertEq(registeredAt, block.timestamp);
        assertEq(expiresAt, block.timestamp + REGISTRATION_DURATION);
        assertFalse(isExpired);
    }
    
    function testGetOwnerNames() public {
        vm.startPrank(user1);
        registry.registerName{value: REGISTRATION_FEE}("alice");
        registry.registerName{value: REGISTRATION_FEE}("bob");
        vm.stopPrank();
        
        string[] memory names = registry.getOwnerNames(user1);
        assertEq(names.length, 2);
    }
    
    /*//////////////////////////////////////////////////////////////
                          ADMIN FUNCTION TESTS
    //////////////////////////////////////////////////////////////*/
    
    function testSetRegistrationFee() public {
        uint256 newFee = 0.02 ether;
        
        vm.prank(owner);
        vm.expectEmit(false, false, false, true);
        emit RegistrationFeeUpdated(REGISTRATION_FEE, newFee);
        
        registry.setRegistrationFee(newFee);
        
        assertEq(registry.registrationFee(), newFee);
    }
    
    function testCannotSetRegistrationFeeAsNonOwner() public {
        vm.prank(user1);
        vm.expectRevert("Ownable: caller is not the owner");
        registry.setRegistrationFee(0.02 ether);
    }
    
    function testPause() public {
        vm.prank(owner);
        registry.pause();
        
        vm.prank(user1);
        vm.expectRevert("Pausable: paused");
        registry.registerName{value: REGISTRATION_FEE}("alice");
    }
    
    function testUnpause() public {
        vm.prank(owner);
        registry.pause();
        
        vm.prank(owner);
        registry.unpause();
        
        vm.prank(user1);
        registry.registerName{value: REGISTRATION_FEE}("alice");
        
        assertEq(registry.getNameOwner("alice"), user1);
    }
    
    function testCannotPauseAsNonOwner() public {
        vm.prank(user1);
        vm.expectRevert("Ownable: caller is not the owner");
        registry.pause();
    }
    
    function testCannotUnpauseAsNonOwner() public {
        vm.prank(owner);
        registry.pause();
        
        vm.prank(user1);
        vm.expectRevert("Ownable: caller is not the owner");
        registry.unpause();
    }
    
    function testWithdrawFees() public {
        // Register some names to accumulate fees
        vm.prank(user1);
        registry.registerName{value: REGISTRATION_FEE}("alice");
        
        vm.prank(user2);
        registry.registerName{value: REGISTRATION_FEE}("bob");
        
        uint256 contractBalance = address(registry).balance;
        assertEq(contractBalance, REGISTRATION_FEE * 2);
        
        address payable recipient = payable(address(99));
        uint256 initialBalance = recipient.balance;
        
        vm.prank(owner);
        registry.withdrawFees(recipient);
        
        assertEq(recipient.balance, initialBalance + contractBalance);
        assertEq(address(registry).balance, 0);
    }
    
    function testCannotWithdrawFeesAsNonOwner() public {
        vm.prank(user1);
        vm.expectRevert("Ownable: caller is not the owner");
        registry.withdrawFees(payable(user1));
    }
    
    function testCannotWithdrawFeesToZeroAddress() public {
        vm.prank(owner);
        vm.expectRevert(Uchainregistry.InvalidAddress.selector);
        registry.withdrawFees(payable(address(0)));
    }
    
    /*//////////////////////////////////////////////////////////////
                          FUZZ TESTS
    //////////////////////////////////////////////////////////////*/
    
    function testFuzzRegisterName(string calldata name) public {
        // Only test valid names
        if (bytes(name).length < 3 || bytes(name).length > 32) {
            vm.expectRevert(Uchainregistry.InvalidName.selector);
            vm.prank(user1);
            registry.registerName{value: REGISTRATION_FEE}(name);
            return;
        }
        
        // Check for invalid characters
        bytes memory nameBytes = bytes(name);
        bool hasInvalidChar = false;
        for (uint256 i = 0; i < nameBytes.length; i++) {
            bytes1 char = nameBytes[i];
            bool isValid = (char >= 0x30 && char <= 0x39) || // 0-9
                          (char >= 0x61 && char <= 0x7A) || // a-z
                          (char >= 0x41 && char <= 0x5A) || // A-Z
                          (char == 0x2D);                    // hyphen
            if (!isValid) {
                hasInvalidChar = true;
                break;
            }
        }
        
        if (hasInvalidChar) {
            vm.expectRevert(Uchainregistry.InvalidName.selector);
            vm.prank(user1);
            registry.registerName{value: REGISTRATION_FEE}(name);
            return;
        }
        
        // Should succeed for valid names
        vm.prank(user1);
        registry.registerName{value: REGISTRATION_FEE}(name);
        assertEq(registry.getNameOwner(name), user1);
    }
    
    function testFuzzRegistrationFee(uint256 fee) public {
        vm.assume(fee > 0 && fee < 100 ether);
        
        vm.prank(owner);
        registry.setRegistrationFee(fee);
        
        assertEq(registry.registrationFee(), fee);
        
        vm.prank(user1);
        registry.registerName{value: fee}("alice");
        
        assertEq(registry.getNameOwner("alice"), user1);
    }
    
    /*//////////////////////////////////////////////////////////////
                        INTEGRATION TESTS
    //////////////////////////////////////////////////////////////*/
    
    function testCompleteLifecycle() public {
        // Register
        vm.prank(user1);
        registry.registerName{value: REGISTRATION_FEE}("alice");
        
        // Renew
        vm.prank(user1);
        registry.renewName{value: REGISTRATION_FEE}("alice");
        
        // Transfer
        vm.prank(user1);
        registry.transferName("alice", user2);
        
        // Release
        vm.prank(user2);
        registry.releaseName("alice");
        
        // Re-register by different user
        vm.prank(user3);
        registry.registerName{value: REGISTRATION_FEE}("alice");
        
        assertEq(registry.getNameOwner("alice"), user3);
    }
    
    function testMultipleUsersMultipleNames() public {
        // User1 registers 3 names
        vm.startPrank(user1);
        registry.registerName{value: REGISTRATION_FEE}("alice");
        registry.registerName{value: REGISTRATION_FEE}("bob");
        registry.registerName{value: REGISTRATION_FEE}("charlie");
        vm.stopPrank();
        
        // User2 registers 2 names
        vm.startPrank(user2);
        registry.registerName{value: REGISTRATION_FEE}("david");
        registry.registerName{value: REGISTRATION_FEE}("eve");
        vm.stopPrank();
        
        assertEq(registry.getOwnerNames(user1).length, 3);
        assertEq(registry.getOwnerNames(user2).length, 2);
        
        // User1 transfers one to user2
        vm.prank(user1);
        registry.transferName("alice", user2);
        
        assertEq(registry.getOwnerNames(user1).length, 2);
        assertEq(registry.getOwnerNames(user2).length, 3);
    }
}
