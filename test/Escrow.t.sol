// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console2} from "forge-std/Test.sol";
import {Escrow} from "../src/Escrow.sol";

contract EscrowTest is Test {

    Escrow public escrow;

    address constant private BUYER = 0x23618e81E3f5cdF7f54C3d65f7FBc0aBf5B21E8f;
    address constant private SELLER = 0xa0Ee7A142d267C1f36714E4a8F75612F20a79720;
    address constant private NOBODY = 0x14dC79964da2C08b23698B3D3cc7Ca32193d9955;
    uint constant private PRICE = 1000000000;

    function setUp() public {
        escrow = new Escrow();
        assertEq(escrow.totalInEscrow(), 0);
        assertEq(escrow.numActiveTransactions(), 0);
        assertEq(escrow.numCompletedTransactions(), 0);
        assertEq(address(SELLER).balance, 0);
        // Give the buyer some money
        deal(BUYER, PRICE * 10);
        assertEq(address(BUYER).balance, PRICE * 10);
    }

    function test_purchaseCanceled() public {
        // As the buyer, purchase an item
        vm.startPrank(BUYER);
        uint startingBalance = address(BUYER).balance;
        uint txId = escrow.purchaseItem{value: PRICE}(SELLER, "Flower Vase");
        assertTrue(escrow.checkTransactionStatus(txId) == Escrow.Status.PURCHASED);
        assertEq(escrow.numActiveTransactions(), 1);
        // Money from the buyer is now in escrow
        assertEq(address(BUYER).balance, startingBalance - PRICE);
        assertEq(escrow.totalInEscrow(), PRICE);

        // Cancel the purchase
        escrow.cancelPurchase(txId);
        assertTrue(escrow.checkTransactionStatus(txId) == Escrow.Status.CANCELED);
        assertEq(escrow.numActiveTransactions(), 0);
        assertEq(escrow.numCompletedTransactions(), 1);
        // Money has been refunded to the buyer
        assertEq(address(BUYER).balance, startingBalance);
        assertEq(escrow.totalInEscrow(), 0);
    }

    function test_purchaseReceived() public {
        // As the buyer, purchase an item
        vm.startPrank(BUYER);
        uint startingBalance = address(BUYER).balance;
        uint txId = escrow.purchaseItem{value: PRICE}(SELLER, "Flower Vase");

        // As the seller, ship the item
        vm.startPrank(SELLER);
        escrow.shipItem(txId);
        assertTrue(escrow.checkTransactionStatus(txId) == Escrow.Status.SHIPPED);

        // Stop an unauthorized user
        vm.startPrank(NOBODY);
        vm.expectRevert("Not the buyer");
        escrow.itemReceived(txId);

        // As the buyer, acknowledge receipt of the item
        vm.startPrank(BUYER);
        escrow.itemReceived(txId);
        assertTrue(escrow.checkTransactionStatus(txId) == Escrow.Status.RECEIVED);
        assertEq(escrow.numActiveTransactions(), 0);
        assertEq(escrow.numCompletedTransactions(), 1);
        // Payment is released to the seller
        assertEq(address(SELLER).balance, PRICE);
        assertEq(address(BUYER).balance, startingBalance - PRICE);
        assertEq(escrow.totalInEscrow(), 0);
    }
}
