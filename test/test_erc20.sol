// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "../lib/forge-std/src/Test.sol";
import "../src/erc20.sol";

abstract contract SharedSetup {
    uint256 constant TOTAL_SUPPLY = 2**96;
    string constant TOKEN_NAME = "TestToken";
    string constant TOKEN_SYMBOL = "Test";
}

/// @title Tests for the transfer function
contract erc20Test is Test, SharedSetup {
    ERC20 public erc20;
    address immutable receiver;
    address immutable sender;

    constructor () {
        receiver = address(1);
        sender = address(this);
    }

    /// @dev An optional function invoked before each test case is run
    function setUp() public {
        erc20 = new ERC20(TOKEN_NAME, TOKEN_SYMBOL, TOTAL_SUPPLY);
        assertEq(TOTAL_SUPPLY, erc20.balanceOf(sender));
        assertEq(TOKEN_NAME, erc20.name());
        assertEq(TOTAL_SUPPLY, erc20.balanceOf(sender));
    }

    function _transfer(address _receiver, uint256 amount) internal {
        uint256 receiverBalanceBefore = erc20.balanceOf(_receiver);
        erc20.transfer(_receiver, amount);
        uint256 receiverBalanceAfter = erc20.balanceOf(_receiver);
        assertEq(receiverBalanceAfter, receiverBalanceBefore + amount);
        assertEq(TOTAL_SUPPLY, erc20.balanceOf(sender) + receiverBalanceAfter);
    }

    function _standardTransfer(address _receiver, uint256 amount) internal {
        uint256 receiverBalanceBefore = erc20.balanceOf(_receiver);
        erc20.standardTransfer(_receiver, amount);
        uint256 receiverBalanceAfter = erc20.balanceOf(_receiver);
        assertEq(receiverBalanceAfter, receiverBalanceBefore + amount);
        assertEq(TOTAL_SUPPLY, erc20.balanceOf(sender) + receiverBalanceAfter);
    }
    
    /// @dev Case 1: transfer with amount < balance
    function testTransferBelowBalance() public {
        uint256 amount = erc20.balanceOf(sender) / 2;
        _transfer(receiver, amount);
    }

    /// @dev Case 1: standardTransfer with amount < balance
    function testStandardTransferBelowBalance() public {
        uint256 amount = erc20.balanceOf(sender) / 2;
        _standardTransfer(receiver, amount);
    }
    
    /// @dev Case2: Transfer with amount = balance
    function testTransferMaxBalance() public {
        uint256 amount = erc20.balanceOf(sender);
        _transfer(receiver, amount);
    }

    /// @dev Case2: standardTransfer with amount = balance
    function testStandardTransferMaxBalance() public {
        uint256 amount = erc20.balanceOf(sender);
        _standardTransfer(receiver, amount);
    }

    /// @dev Case 3: Transfer with amount > balance, results in amount = balance
    function testTransferAboveBalance() public {   
        // prevent overflow with wrong config
        _transfer(receiver, 1*10**18);
        // amount > balanceOf(msg.sender), can't overflow
        uint256 aboveMaxBalance = erc20.balanceOf(sender) + 1*10**18;
        uint256 actualMaxBalance = erc20.balanceOf(sender);
        // Case 3 Logic:
        uint256 receiverBalanceBefore = erc20.balanceOf(receiver);
        erc20.transfer(receiver, aboveMaxBalance);
        uint256 receiverBalanceAfter = erc20.balanceOf(receiver);
        assertEq(0, erc20.balanceOf(sender));
        assertEq(receiverBalanceAfter, receiverBalanceBefore + actualMaxBalance);
        assertEq(TOTAL_SUPPLY, erc20.balanceOf(sender) + receiverBalanceAfter);
    }

    /// @dev Case 3: standardTransfer with amount > balance, should fail
    function testStandardTransferAboveBalance() public {   
        // prevent overflow with wrong config
        _standardTransfer(receiver, 1*10**18);
        // amount > balanceOf(msg.sender), can't overflow
        uint256 aboveMaxBalance = erc20.balanceOf(sender) + 1*10**18;
        // Case 3 Logic:
        uint256 receiverBalanceBefore = erc20.balanceOf(receiver);
        vm.expectRevert(bytes("balance too low"));
        erc20.standardTransfer(receiver, aboveMaxBalance);
        uint256 receiverBalanceAfter = erc20.balanceOf(receiver);
        assertEq(TOTAL_SUPPLY, erc20.balanceOf(sender) + receiverBalanceAfter);
        assertEq(receiverBalanceBefore, receiverBalanceAfter);
    }

    /// @dev fuzz test for standardTransfer:
    function testStandardTransfer(uint96 amount) public {
        _standardTransfer(receiver, amount);
    }
    
    /// @dev fuzz tests for transfer:
    function testTransfer(uint96 amount) public {
        _transfer(receiver, amount);
    }
}

/// @title Contract for gas testing, no asserts checked here
contract gasTest is Test {
    ERC20 public erc20;
    address public receiver = address(1);
    address public sender = address(this);

    function setUp() public {
        erc20 = new ERC20("GasTest", "GST", 2**96);
    }

    function testStandardTransferGas() public {
        uint256 amount = erc20.balanceOf(sender);
        erc20.standardTransfer(receiver, amount);
    }
    
    function testTransferGas() public {
        uint256 amount = erc20.balanceOf(sender);
        erc20.transfer(receiver, amount);
    }

    function testTransferGasLoop() public {
        address _receiver = address(1);
        uint256 x = 36;
        uint256 amount = 2**x;
        uint256 _wamount = 1;
        // Stops at 2**(x-1)-1 tokens transferred
        while (_wamount*2 < amount) {
            erc20.transfer(_receiver, _wamount);
            _wamount = _wamount*2;
            _receiver = address(uint160(uint(keccak256(abi.encodePacked(_wamount)))));
        }
    }

    function testStandardTransferGasLoop() public {
        address _receiver = address(1);
        uint256 x = 36;
        uint256 amount = 2**x;
        uint256 _wamount = 1;
        // Stops at 2**(x-1)-1 tokens transferred
        while (_wamount*2 < amount) {
            erc20.standardTransfer(_receiver, _wamount);
            _wamount = _wamount*2;
            _receiver = address(uint160(uint(keccak256(abi.encodePacked(_wamount)))));
        }
    }
}
