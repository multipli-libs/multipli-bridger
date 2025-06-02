// SPDX-License-Identifier: MIT


pragma solidity >=0.4.22 <0.9.0;


import {Test, stdStorage, StdStorage, console} from "forge-std/Test.sol";

import {MultipliBridger} from "../../src/MultipliBridger.sol";
import {DeployMultipliBridger} from "../../script/deploy/DeployMultipliBridger.s.sol";

import {ERC20Mock} from "@openzeppelin/contracts/mocks/token/ERC20Mock.sol";
import {IERC20} from "@openzeppelin/contracts/interfaces/IERC20.sol";




contract TestMultipliBridger is Test {
    using stdStorage for StdStorage;

    address narutoAddr;
    uint256 narutoPrivKey;

    address sasukeAddr;
    uint256 sasukePrivKey;

    address minatoAddr;
    uint256 minatoPrivKey;

    ERC20Mock token;

    MultipliBridger bridger;

    modifier deployerIsNaruto () {
        DeployMultipliBridger deployer = new DeployMultipliBridger();
        bridger = deployer.deploy(narutoPrivKey);
        _;
    }

    modifier deployerIsSasuke () {
        DeployMultipliBridger deployer = new DeployMultipliBridger();
        bridger = deployer.deploy(sasukePrivKey);
        _;
    }

    modifier authorizeUser (address user) {
        require(address(bridger) != address(0), "bridger not deployed");

        vm.startPrank(bridger.owner());
        bridger.authorize(user, true);
        vm.stopPrank();
        _;
    } 
    modifier unauthorizeUser (address user) {
        require(address(bridger) != address(0), "bridger not deployed");

        vm.startPrank(bridger.owner());
        bridger.authorize(user, false);
        vm.stopPrank();
        _;
    }

    modifier registerToken (address tokenAddr) {
        require(address(bridger) != address(0), "bridger not deployed");

        vm.startPrank(bridger.owner());
        bridger.registerToken(tokenAddr);
        vm.stopPrank();
        _;
    }

    function setUp() public {
        (narutoAddr, narutoPrivKey) = makeAddrAndKey("naruto");
        (sasukeAddr, sasukePrivKey) = makeAddrAndKey("sasuke");
        (minatoAddr, minatoPrivKey) = makeAddrAndKey("minato");

        console.log("Naruto Address: %s", narutoAddr);
        console.log("Sasuke Address: %s", sasukeAddr);
        console.log("Minato Address: %s", minatoAddr);

        token = new ERC20Mock();
        
        }

    function testOwnerIsInitializedCorrectlyForNaruto() public deployerIsNaruto {
        // make sure it is initialized
        assertNotEq(bridger.owner(), address(0));

        // ensure naruto is the owner of the contract
        assertEq(bridger.owner(), narutoAddr);

        //ensure naruto is added to the list of authorized users
        assertEq(bridger.authorized(narutoAddr), true);
    }

    function testOwnerIsInitializedCorrectlyForSasuke() public deployerIsSasuke {
        // make sure it is initialized
        assertNotEq(bridger.owner(), address(0));

        // ensure sasuke is the owner of the contract
        assertEq(bridger.owner(), sasukeAddr);

        // ensure sasuke is added to the list of authorized users
        assertTrue(bridger.authorized(sasukeAddr));
    }

    function testInitializeCanBeCalledOnlyOnce() public deployerIsNaruto {
        vm.startPrank(narutoAddr);
        vm.expectRevert("Initializable: contract is already initialized");
        bridger.initialize();
        vm.stopPrank();
    }

    function testNonOwnerCallingAuthorizeReverts() public deployerIsNaruto {
        vm.startPrank(sasukeAddr);

        vm.expectRevert("Ownable: caller is not the owner");
        bridger.authorize(minatoAddr, true);

        vm.stopPrank();
    }

    function testOwnerCallingAuthorizeIsSuccess() public deployerIsNaruto {
        vm.startPrank(narutoAddr);

        // sanity check to ensure minato is not a authorized user
        assertFalse(bridger.authorized(minatoAddr));

        // authorize Minato
        bridger.authorize(minatoAddr, true);
        assertTrue(bridger.authorized(minatoAddr));

        // unauthorize Minato
        bridger.authorize(minatoAddr, false);
        assertFalse(bridger.authorized(minatoAddr));

        vm.stopPrank();
    }

    function testAuthorizeOnZeroAddressReverts() public deployerIsNaruto {
        vm.startPrank(narutoAddr);

        address user = address(0);

        // sanity check to ensure user is not a authorized user
        assertFalse(bridger.authorized(user));

        // This should now revert with the new validation
        vm.expectRevert("Authorization: user cannot be zero address");
        bridger.authorize(user, true);

        vm.stopPrank();
    }

    function testAuthorizeRevertsOnDuplicateStatus() public deployerIsNaruto {
        vm.startPrank(narutoAddr);

        // First, authorize minato
        bridger.authorize(minatoAddr, true);
        assertTrue(bridger.authorized(minatoAddr));

        // Try to authorize again with same status - should revert
        vm.expectRevert("Authorization: user already has this authorization status");
        bridger.authorize(minatoAddr, true);

        // Now try to unauthorize minato
        bridger.authorize(minatoAddr, false);
        assertFalse(bridger.authorized(minatoAddr));

        // Try to unauthorize again with same status - should revert
        vm.expectRevert("Authorization: user already has this authorization status");
        bridger.authorize(minatoAddr, false);

        vm.stopPrank();
}

    // Note: Depending on whom you ask, this is either a security feature or a bug
    // Owner can be removed from the list of authorized users
    //      This action in turn will prevent the owner from calling the following methods
    //            - `addFunds`, 
    //            - `addFundsNative`, 
    //            - `withdraw`, 
    //            - `withdrawNative`, 
    //            - `removeFunds`, 
    //            - `removeFundsNative`
    function testAuthorizeIsCalledByOwnerToUnauthorizeOwner() public deployerIsNaruto {
        vm.startPrank(narutoAddr);
        
        // Sanity check to make sure naruto is part of the Authorized users
        assertTrue(bridger.authorized(narutoAddr));

        bridger.authorize(narutoAddr, false);

        assertFalse(bridger.authorized(narutoAddr));

        vm.stopPrank();
    }

    function testTransferOwnerRevertsWhenCalledByNonOwner() public deployerIsNaruto {
        vm.startPrank(minatoAddr);
        vm.expectRevert("Ownable: caller is not the owner");
        bridger.transferOwner(minatoAddr);
        vm.stopPrank();
    }

    function testTransferOwnerRevertsWhenUserIsZero() public deployerIsNaruto {
        vm.startPrank(narutoAddr);
        vm.expectRevert("Ownable: new owner is the zero address");
        bridger.transferOwner(address(0));
        vm.stopPrank();
    }

    function testTransferOwnerRevertsWhenNewOwnerIsSameAsCurrent() public deployerIsNaruto {
        vm.startPrank(narutoAddr);
        vm.expectRevert("Ownable: new owner is the same as current owner");
        bridger.transferOwnership(narutoAddr); // Try to transfer to self
        vm.stopPrank();
    }

    function testTransferOwnershipSuccess() public deployerIsNaruto {
        vm.startPrank(narutoAddr);
        
        // Verify initial owner
        assertEq(bridger.owner(), narutoAddr);
        
        // Transfer ownership to minato
        bridger.transferOwnership(minatoAddr);
        
        // Verify ownership has changed
        assertEq(bridger.owner(), minatoAddr);
        
        vm.stopPrank();
    }

    function testAuthorizationStatusAfterOwnershipTransfer() public deployerIsNaruto {
        vm.startPrank(narutoAddr);
        
        // Authorize minato
        bridger.authorize(minatoAddr, true);
        assertTrue(bridger.authorized(minatoAddr));
        
        // Transfer ownership to sasuke
        bridger.transferOwnership(sasukeAddr);
        
        vm.stopPrank();
        
        // Check that minato is still authorized after ownership transfer
        assertTrue(bridger.authorized(minatoAddr));
        
        // But naruto (old owner) should no longer be able to modify authorizations
        vm.startPrank(narutoAddr);
        vm.expectRevert("Ownable: caller is not the owner");
        bridger.authorize(minatoAddr, false);
        vm.stopPrank();
        
        // New owner should be able to modify authorizations
        vm.startPrank(sasukeAddr);
        bridger.authorize(minatoAddr, false);
        assertFalse(bridger.authorized(minatoAddr));
        vm.stopPrank();
    }

    function testRenounceOwnershipRevertsWhenCalledByNonOwner() public deployerIsNaruto {
        vm.startPrank(minatoAddr);
        vm.expectRevert("Ownable: caller is not the owner");
        bridger.renounceOwnership();
        vm.stopPrank();
    }

    function testRenounceOwnershipAlwaysRevertsWhenCalledByOwner() public deployerIsNaruto {
        vm.startPrank(narutoAddr);
        vm.expectRevert("Unable to renounce ownership");
        bridger.renounceOwnership();
        vm.stopPrank();
    }

    /* Token Registration Tests */
    function testRegisterTokenRevertsWhenCalledByUnAuthorizedUser() public deployerIsNaruto {
        vm.startPrank(minatoAddr);
        vm.expectRevert("UNAUTHORIZED");
        bridger.registerToken(address(token));
        vm.stopPrank();
    }

    function testRegisterTokenRevertsWhenTokenAddressIsZero() public deployerIsNaruto {
        vm.startPrank(narutoAddr);
        vm.expectRevert("Cannot register zero address as token");
        bridger.registerToken(address(0));
        vm.stopPrank();
    }

    function testRegisterTokenIsSuccessWhenCalledByAuthorizedUser() public deployerIsNaruto {
        vm.startPrank(narutoAddr);
        
        // Ensure token is not already registered
        assertFalse(bridger.registeredTokens(address(token)));
        
        // Set emit expectations
        vm.expectEmit(true, true, false, true);
        emit MultipliBridger.TokenRegistered(address(token), narutoAddr);
        
        // Register token
        bridger.registerToken(address(token));
        
        // Verify token is registered
        assertTrue(bridger.registeredTokens(address(token)));
        
        vm.stopPrank();
    }
    
    function testRegisterTokenRevertsWhenTokenIsAlreadyRegistered() public deployerIsNaruto {
        vm.startPrank(narutoAddr);
        
        // Register token first
        bridger.registerToken(address(token));
        
        // Try to register again
        vm.expectRevert("Token already registered");
        bridger.registerToken(address(token));
        
        vm.stopPrank();
    }

    function testDeregisterTokenRevertsWhenCalledByUnauthorizedUser() public deployerIsNaruto {
        vm.startPrank(minatoAddr);
        vm.expectRevert("UNAUTHORIZED");
        bridger.deregisterToken(address(token));
        vm.stopPrank();
    }
    
    function testDeregisterTokenRevertsWhenTokenIsNotRegistered() public deployerIsNaruto {
        vm.startPrank(narutoAddr);
        vm.expectRevert("Token not registered");
        bridger.deregisterToken(address(token));
        vm.stopPrank();
    }
    
    function testDeregisterTokenIsSuccessWhenCalledByAuthorizedUser() public deployerIsNaruto {
        vm.startPrank(narutoAddr);
        
        // Register token first
        bridger.registerToken(address(token));
        assertTrue(bridger.registeredTokens(address(token)));
        
        // Set emit expectations
        vm.expectEmit(true, true, false, true);
        emit MultipliBridger.TokenDeregistered(address(token), narutoAddr);
        
        // Unregister token
        bridger.deregisterToken(address(token));
        
        // Verify token is unregistered
        assertFalse(bridger.registeredTokens(address(token)));
        
        vm.stopPrank();
    }

    /* Modified Deposit Tests to include token registration */
    function testDepositRevertsWhenTokenIsNotRegistered() public deployerIsNaruto {
        vm.startPrank(minatoAddr);

        // ensure balance of Minato is 11 ether
        deal(address(token), minatoAddr, 11 ether);
        assertEq(token.balanceOf(minatoAddr), 11 ether);
        
        // amount to deposit
        uint256 amountToDeposit = 10e18;
        token.approve(address(bridger), amountToDeposit);

        // Token is not registered, so deposit should revert
        vm.expectRevert("Token is not registered");
        bridger.deposit(address(token), amountToDeposit);

        vm.stopPrank();
    }

    function testAddFundsRevertsWhenCalledByUnAuthorizedUser() public deployerIsNaruto {
        // Minato is an unauthorized user
        vm.startPrank(minatoAddr);

        // approve spender
        uint256 amount = 10e18;
        token.approve(address(bridger), amount);

        // verify that addFunds reverts
        vm.expectRevert("UNAUTHORIZED");
        bridger.addFunds(address(token), amount);

        vm.stopPrank();

    }

    function testAddFundsIsSuccessWhenCalledByAuthorizedUser() public deployerIsNaruto authorizeUser(minatoAddr){
        // Minato is an authorized user
        vm.startPrank(minatoAddr);

        // find token balance of contract
        uint256 balanceBefore = token.balanceOf(address(bridger));

        uint256 amount = 10e18;

        // ensure user has sufficient balance
        deal(address(token), minatoAddr, amount);
        // approve spender
        token.approve(address(bridger), amount);

        // Add funds to the contract
        bridger.addFunds(address(token), amount);

        // find current token balance of contract
        uint256 balanceNow = token.balanceOf(address(bridger));

        // verify that the balance has increased by `amount`
        assertEq(balanceBefore + amount, balanceNow);

        vm.stopPrank();
    }

    function testAddFundsRevertsWhenCalledByOwnerNotInAuthorizedUser() public deployerIsNaruto authorizeUser(minatoAddr) unauthorizeUser(narutoAddr) {

        // sanity checks
        assertEq(bridger.owner(), narutoAddr);
        assertEq(bridger.authorized(narutoAddr), false);


        // Naruto is owner of the contract but an unauthorized user
        vm.startPrank(narutoAddr);
        
        uint256 amount = 10e18;

        vm.expectRevert("UNAUTHORIZED");
        // Add funds to the contract
        bridger.addFunds(address(token), amount);

        vm.stopPrank();
    }

    function testAddFundsNativeRevertsWhenCalledByUnAuthorizedUser() public deployerIsNaruto {
        // Minato is an unauthorized user
        vm.startPrank(minatoAddr);

        // ensure user has sufficient balance
        uint256 amount = 1e18;
        deal(minatoAddr, amount);

        // verify that addFunds reverts
        vm.expectRevert("UNAUTHORIZED");
        bridger.addFundsNative{value: amount}();

        vm.stopPrank();

    }

    function testAddFundsNativeIsSuccessWhenCalledByAuthorizedUser() public deployerIsNaruto authorizeUser(minatoAddr){
        uint256 amount = 1e18;
        uint256 initialContractBalance = 2 ether;
        uint256 initialBalanceOfMinato = amount + 1e18; // amount + buffer
        
        
        // ensure user has sufficient balance
        deal(minatoAddr, initialBalanceOfMinato); 
        
        // set initial eth balance of the contract
        deal(address(bridger), initialContractBalance);

        // find token balance of contract
        uint256 balanceBefore = address(bridger).balance;
        assertEq(balanceBefore, 2 ether); // sanity check

        
        // Minato is an authorized user
        vm.startPrank(minatoAddr);

        // Add funds to the contract
        bridger.addFundsNative{value: amount}();

        // find current token balance of contract
        uint256 balanceNow = address(bridger).balance;

        // verify that the balance has increased by `amount`
        assertEq(balanceBefore + amount, balanceNow);

        vm.stopPrank();
    }

    function testDepositWhenCalledWithInsufficientBalanceReverts() public deployerIsNaruto registerToken(address(token)) {
        vm.startPrank(minatoAddr);

        // ensure balance is 0
        assertEq(token.balanceOf(minatoAddr), 0);
        
        // amount to deposit
        uint256 amountToDeposit = 10e18;

        token.approve(address(bridger), amountToDeposit);

        // this depends on the behavior of the ERC20 contract
        // should this test be added here? 
        vm.expectRevert("TransferHelper: TRANSFER_FROM_FAILED");
        bridger.deposit(address(token), amountToDeposit);

        // verify that balance has not been modified
        assertEq(token.balanceOf(minatoAddr), 0);
        assertEq(token.balanceOf(address(bridger)), 0);

        vm.stopPrank();
    }

    function testDepositWhenCalledWithoutApprovalReverts() public deployerIsNaruto registerToken(address(token)) {
        vm.startPrank(minatoAddr);

        // ensure balance of Minato is 11 ether
        deal(address(token), minatoAddr, 11 ether);
        assertEq(token.balanceOf(minatoAddr), 11 ether);
        
        // amount to deposit
        uint256 amountToDeposit = 10e18;

        // sanity check to ensure token allowance is 0
        assertEq(token.allowance(minatoAddr, address(bridger)), 0);

        // this depends on the behavior of the ERC20 contract
        // should this test be added here? 
        // Ideally, this should revert due to the lack of approval amount
        vm.expectRevert("TransferHelper: TRANSFER_FROM_FAILED");
        bridger.deposit(address(token), amountToDeposit);

        // verify that balance has not been modified
        assertEq(token.balanceOf(minatoAddr), 11 ether);
        assertEq(token.balanceOf(address(bridger)), 0);

        vm.stopPrank();
    }

    function testDepositIsSuccess() public deployerIsNaruto registerToken(address(token)) {
        // ensure contract has some balance
        deal(address(token), address(bridger), 1 ether);
        assertEq(token.balanceOf(address(bridger)), 1 ether);
        uint256 contractBalanceBefore = 1 ether;

        // ensure balance of Minato is 11 ether
        deal(address(token), minatoAddr, 11e18);
        assertEq(token.balanceOf(minatoAddr), 11e18);

        
        vm.startPrank(minatoAddr);
        // amount to deposit
        uint256 amountToDeposit = 10e18;
        token.approve(address(bridger), amountToDeposit);

        // set emit expectations
        vm.expectEmit(true, true, false, true);
        emit MultipliBridger.BridgedDeposit(minatoAddr, address(token), amountToDeposit);

        // make the call
        bridger.deposit(address(token), amountToDeposit);

        // get current balance
        // and verify the balances match up after deposit is made
        uint256 contractBalanceNow = token.balanceOf(address(bridger));
        assertEq(contractBalanceNow, contractBalanceBefore + amountToDeposit);

        vm.stopPrank();
    }

    function testDepositNativeIsSuccess() public deployerIsNaruto {
        // ensure contract has some balance
        deal(address(bridger), 1 ether);
        assertEq(address(bridger).balance, 1 ether);
        uint256 contractBalanceBefore = address(bridger).balance; // 1 ether

        // ensure balance of Minato is 11
        deal(minatoAddr, 11 ether);
        assertEq(address(minatoAddr).balance, 11 ether);

    
        vm.startPrank(minatoAddr);
        // amount to deposit
        uint256 amountToDeposit = 10 ether;

        // set emit expectations
        vm.expectEmit(true, true, false, true);
        emit MultipliBridger.BridgedDeposit(minatoAddr, address(0), amountToDeposit);

        // make the call
        bridger.depositNative{value: amountToDeposit}();

        // get current balance
        // and verify the balances match up after deposit is made
        uint256 contractBalanceNow = address(bridger).balance;
        assertEq(contractBalanceNow, contractBalanceBefore + amountToDeposit);

        vm.stopPrank();
    }

    function testDepositNativeIsSuccessOnZeroAmount() public deployerIsNaruto {
        // ensure contract has some balance
        deal(address(bridger), 1 ether);
        assertEq(address(bridger).balance, 1 ether);
        uint256 contractBalanceBefore = address(bridger).balance; // 1 ether

        // ensure balance of Minato is 11
        deal(minatoAddr, 11 ether);
        assertEq(address(minatoAddr).balance, 11 ether);

        
        vm.startPrank(minatoAddr);
        // amount to deposit
        uint256 amountToDeposit = 0 ether;

        // set emit expectations
        vm.expectEmit(true, true, false, true);
        emit MultipliBridger.BridgedDeposit(minatoAddr, address(0), amountToDeposit);

        // make the call
        bridger.depositNative{value: amountToDeposit}();

        // get current balance
        // and verify the balances match up after deposit is made
        uint256 contractBalanceNow = address(bridger).balance;
        assertEq(contractBalanceNow, contractBalanceBefore);

        vm.stopPrank();
    }

    function testRemoveFundsRevertsWhenCalledByUnAuthorizedUser() public deployerIsNaruto {
        // sanity check to verify Minato is not an authorized user
        assertEq(bridger.authorized(minatoAddr), false);

        // ensure there is balance in the contract
        deal(address(token), address(bridger), 10e18);
        assertEq(token.balanceOf(address(bridger)), 10e18); // sanity check

        vm.startPrank(minatoAddr);
        vm.expectRevert("UNAUTHORIZED");        
        bridger.removeFunds(address(token), minatoAddr, 1e18);

        vm.stopPrank();

    }

    function testRemoveFundsIsSuccessWhenCalledByAuthorizedUser() public deployerIsNaruto authorizeUser(minatoAddr) {
        // sanity check to verify Minato is an authorized user
        assertEq(bridger.authorized(minatoAddr), true);

        uint256 initialContractBalance = 10e18;

        // ensure there is balance in the contract
        deal(address(token), address(bridger), initialContractBalance);
        assertEq(token.balanceOf(address(bridger)), initialContractBalance); // sanity check

        // ensure balance of Minato is 0
        assertEq(token.balanceOf(minatoAddr), 0);

        vm.startPrank(minatoAddr);
        uint256 balanceToRemove = 2e18;
        bridger.removeFunds(address(token), minatoAddr, balanceToRemove);

        // verify the balance of the contract after calling `removeFunds`
        assertEq(token.balanceOf(address(bridger)), initialContractBalance - balanceToRemove);
        // verify the balance of Minato after calling `removeFunds`
        assertEq(token.balanceOf(minatoAddr), balanceToRemove);

        vm.stopPrank();

    }

    function testRemoveFundsRevertsWhenCalledByAuthorizedUserWithInsufficientContractBalance() public deployerIsNaruto authorizeUser(minatoAddr) {
        // sanity check to verify Minato is an authorized user
        assertEq(bridger.authorized(minatoAddr), true);

        uint256 initialContractBalance = 10e18;

        // ensure there is balance in the contract
        deal(address(token), address(bridger), initialContractBalance);
        assertEq(token.balanceOf(address(bridger)), initialContractBalance); // sanity check

        // ensure balance of Minato is 0
        assertEq(token.balanceOf(minatoAddr), 0);

        vm.startPrank(minatoAddr);
        uint256 balanceToRemove = 20e18;
        vm.expectRevert("TransferHelper: TRANSFER_FAILED");
        bridger.removeFunds(address(token), minatoAddr, balanceToRemove);

        // verify the balance of the contract after calling `removeFunds`
        assertEq(token.balanceOf(address(bridger)), initialContractBalance);
        // verify the balance of Minato after calling `removeFunds`
        assertEq(token.balanceOf(minatoAddr), 0);

        vm.stopPrank();

    }

    function testRemoveFundsNativeRevertsWhenCalledByUnauthorizedUser() public deployerIsNaruto {
        // sanity check to verify Minato is not an authorized user
        assertEq(bridger.authorized(minatoAddr), false);

        // ensure there is balance in the contract
        deal(address(bridger), 10e18);
        assertEq(address(bridger).balance, 10e18); // sanity check

        vm.startPrank(minatoAddr);
        vm.expectRevert("UNAUTHORIZED");        
        bridger.removeFunds(address(token), minatoAddr, 1e18);

        // verify balances remain unchanged
        assertEq(address(bridger).balance, 10e18);
        assertEq(address(minatoAddr).balance, 0);
        assertEq(address(narutoAddr).balance, 0);

        vm.stopPrank();

    }

    function testRemoveFundsNativeRevertsWhenCalledByAuthorizedUserWithInsufficientContractBalance() public deployerIsNaruto authorizeUser(minatoAddr) {
        // sanity check to verify Minato is an authorized user
        assertEq(bridger.authorized(minatoAddr), true);

        uint256 initialContractBalance = 1e18;

        // ensure there is balance in the contract
        deal(address(bridger), initialContractBalance);
        assertEq(address(bridger).balance, initialContractBalance); // sanity check

        // ensure balance of Minato is 0
        assertEq(token.balanceOf(minatoAddr), 0);

        vm.startPrank(minatoAddr);
        uint256 balanceToRemove = 2e18;
        vm.expectRevert("INSUFFICIENT_BALANCE");
        bridger.removeFundsNative(payable(minatoAddr), balanceToRemove);

        // verify the balance of the contract after calling `removeFunds`
        assertEq(address(bridger).balance, initialContractBalance);
        // verify the balance of Minato after calling `removeFunds`
        assertEq(minatoAddr.balance, 0);

        vm.stopPrank();

    }

    function testRemoveFundsNativeIsSuccessWhenCalledByAuthorizedUser() public deployerIsNaruto authorizeUser(minatoAddr) {
        // sanity check to verify Minato is an authorized user
        assertEq(bridger.authorized(minatoAddr), true);

        uint256 initialContractBalance = 10e18;

        // ensure there is ETH in the contract
        deal(address(bridger), initialContractBalance);
        assertEq(address(bridger).balance, initialContractBalance); // sanity check

        // ensure balance of Sasuke is 0
        assertEq(address(sasukeAddr).balance, 0);

        vm.startPrank(minatoAddr);
        uint256 balanceToRemove = 2e18;
        // remove funds to Sasuke
        bridger.removeFundsNative(payable(sasukeAddr), balanceToRemove);

        // verify the balance of the contract after calling `removeFunds`
        assertEq(address(bridger).balance, initialContractBalance - balanceToRemove);
        // verify the balance of Sasuke after calling `removeFunds`
        assertEq(sasukeAddr.balance, balanceToRemove);

        vm.stopPrank();

    }

    function testWithdrawRevertsWhenCalledByUnauthorizedUser() public deployerIsNaruto {
        // sanity check to verify Minato is not an authorized user
        assertEq(bridger.authorized(minatoAddr), false);

        // ensure there is balance in the contract
        deal(address(token), address(bridger), 100e18);
        assertEq(token.balanceOf(address(bridger)), 100e18); // sanity check

        vm.startPrank(minatoAddr);
        vm.expectRevert("UNAUTHORIZED");        
        bridger.withdraw(address(token), minatoAddr, 1e18, "test_1");

        // verify balances remain unchanged
        assertEq(token.balanceOf(address(bridger)), 100e18);
        assertEq(token.balanceOf(minatoAddr), 0);
        assertEq(token.balanceOf(narutoAddr), 0);

        vm.stopPrank();
    }


    function testWithdrawRevertsWhenCalledByAuthorizedUserWithInsufficientContractBalance() public deployerIsNaruto authorizeUser(minatoAddr){
        // sanity check to verify Minato is an authorized user
        assertEq(bridger.authorized(minatoAddr), true);

        // ensure there is balance in the contract
        deal(address(token), address(bridger), 10e18);
        assertEq(token.balanceOf(address(bridger)), 10e18); // sanity check

        vm.startPrank(minatoAddr);  
        vm.expectRevert("TransferHelper: TRANSFER_FAILED");  
        bridger.withdraw(address(token), minatoAddr, 20e18, "test_1");

        // verify balances remain unchanged
        assertEq(token.balanceOf(address(bridger)), 10e18);
        assertEq(token.balanceOf(minatoAddr), 0);
        assertEq(token.balanceOf(narutoAddr), 0);

        vm.stopPrank();
    }

    function testWithdrawIsSuccessfulWhenCalledByAuthenticatedUser() public deployerIsNaruto authorizeUser(minatoAddr){
        // sanity check to verify Minato is an authorized user
        assertEq(bridger.authorized(minatoAddr), true);

        // ensure there is balance in the contract
        deal(address(token), address(bridger), 100e18);
        assertEq(token.balanceOf(address(bridger)), 100e18); // sanity check

        vm.startPrank(minatoAddr);

        uint256 withdrawalAmt = 20e18;
        string memory withdrawalID = "test_1";

        // sanity check to ensure withdrawalID does not exist before `withdraw` method is called
        assertEq(bridger.processedWithdrawalIds(withdrawalID), false);

        bridger.withdraw(address(token), minatoAddr, withdrawalAmt, withdrawalID);

        // verify withdrawalID is set
        assertEq(bridger.processedWithdrawalIds(withdrawalID), true);

        // verify balances after withdraw method is called
        assertEq(token.balanceOf(address(bridger)), 80e18);
        assertEq(token.balanceOf(minatoAddr), 20e18);
        assertEq(token.balanceOf(narutoAddr), 0);

        vm.stopPrank();
    }

    function testWithdrawNativeRevertsWhenCalledByUnauthorizedUser() public deployerIsNaruto {
        // sanity check to verify Minato is not an authorized user
        assertEq(bridger.authorized(minatoAddr), false);

        // ensure there is balance in the contract
        deal(address(bridger), 100e18);
        assertEq(address(bridger).balance, 100e18); // sanity check

        vm.startPrank(minatoAddr);
        vm.expectRevert("UNAUTHORIZED");        
        bridger.withdrawNative(payable(minatoAddr), 1e18, "test_1");

        // verify balances remain unchanged
        assertEq(address(bridger).balance, 100e18);
        assertEq(minatoAddr.balance, 0);
        assertEq(narutoAddr.balance, 0);

        // verify that the withdrawalID is still not used
        assertEq(bridger.processedWithdrawalIds("test_1"), false);

        vm.stopPrank();
    }


    function testWithdrawNativeRevertsWhenCalledByAuthorizedUserWithInsufficientContractBalance() public deployerIsNaruto authorizeUser(minatoAddr){
        // sanity check to verify Minato is an authorized user
        assertEq(bridger.authorized(minatoAddr), true);

        // ensure there is balance in the contract
        deal(address(bridger), 100e18);
        assertEq(address(bridger).balance, 100e18); // sanity check

        vm.startPrank(minatoAddr);  
        vm.expectRevert("INSUFFICIENT_BALANCE");  
        bridger.withdrawNative(payable(minatoAddr), 200e18, "test_1");

        // verify balances remain unchanged
        assertEq(address(bridger).balance, 100e18);
        assertEq(minatoAddr.balance, 0);
        assertEq(narutoAddr.balance, 0);

        // verify that the withdrawalID is still not used
        assertEq(bridger.processedWithdrawalIds("test_1"), false);


        vm.stopPrank();
    }

    function testWithdrawNativeIsSuccessfulWhenCalledByAuthenticatedUser() public deployerIsNaruto authorizeUser(minatoAddr){
        // sanity check to verify Minato is an authorized user
        assertEq(bridger.authorized(minatoAddr), true);

        // ensure there is balance in the contract
        deal(address(bridger), 100e18);
        assertEq(address(bridger).balance, 100e18); // sanity check

        vm.startPrank(minatoAddr);

        uint256 withdrawalAmt = 20e18;
        string memory withdrawalID = "test_1";

        // sanity check to ensure withdrawalID does not exist before `withdraw` method is called
        assertEq(bridger.processedWithdrawalIds(withdrawalID), false);

        bridger.withdrawNative(payable(minatoAddr), withdrawalAmt, withdrawalID);

        // verify withdrawalID is set
        assertEq(bridger.processedWithdrawalIds(withdrawalID), true);

        // verify balances after withdraw method is called
        assertEq(address(bridger).balance, 80e18);
        assertEq(minatoAddr.balance, 20e18);
        assertEq(narutoAddr.balance, 0);

        // verify that the withdrawalID is set
        assertEq(bridger.processedWithdrawalIds(withdrawalID), true);

        vm.stopPrank();
    }

    function testWithdrawNativeRevertsWhenAlreadyUsedWithdrawalIDIsReused() public deployerIsNaruto authorizeUser(minatoAddr){
        string memory withdrawalID = "test_1";
        deal(address(bridger), 100 ether);

        // withdrawal processed with `withdrawalID`
        vm.startPrank(minatoAddr);
        bridger.withdrawNative(payable(sasukeAddr), 1e18, withdrawalID);
        vm.stopPrank();

        // withdrawal processing again with `withdrawalID`
        vm.startPrank(minatoAddr);
        vm.expectRevert("Withdrawal ID Already processed");
        bridger.withdrawNative(payable(sasukeAddr), 1e18, withdrawalID);
        vm.stopPrank();
        
    }

    function testWithdrawRevertsOnDuplicateWithdrawalIDPreviouslyUsedforWithdrawNative() public deployerIsNaruto authorizeUser(minatoAddr) {
        string memory withdrawalID = "test_1";
        deal(address(bridger), 100 ether);
        deal(address(token), address(bridger), 100 ether);

        // withdrawal processed with `withdrawalID`
        vm.startPrank(minatoAddr);
        bridger.withdrawNative(payable(sasukeAddr), 1e18, withdrawalID);
        vm.stopPrank();

        // withdrawal processing again with `withdrawalID`
        vm.startPrank(minatoAddr);
        vm.expectRevert("Withdrawal ID Already processed");
        bridger.withdraw(address(token), sasukeAddr, 1e18, withdrawalID);
        vm.stopPrank();
    }

    function testWithdrawNativeRevertsOnDuplicateWithdrawalIDPreviouslyUsedforWithdraw() public deployerIsNaruto authorizeUser(minatoAddr) {
        string memory withdrawalID = "test_1";
        deal(address(bridger), 100 ether);
        deal(address(token), address(bridger), 100 ether);

        // withdrawal processed with `withdrawalID`
        vm.startPrank(minatoAddr);
        bridger.withdraw(address(token), sasukeAddr, 1e18, withdrawalID);
        vm.stopPrank();

        // withdrawal processing again with `withdrawalID`
        vm.startPrank(minatoAddr);
        vm.expectRevert("Withdrawal ID Already processed");
        bridger.withdrawNative(payable(sasukeAddr), 1e18, withdrawalID);
        vm.stopPrank();
    }

}