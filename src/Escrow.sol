//SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

// Useful for debugging. Remove when deploying to a live network.
import "forge-std/console2.sol";

contract Escrow {

	enum Status {
		DEFAULT, PURCHASED, SHIPPED, RECEIVED, CANCELED
	}

	struct Transaction {
		uint id;
		address buyer;
		address seller;
		string item;
		uint price;
		Status status;
	}

	// When the seller sees this event, they know they need to ship the item
	event ItemPurchased(uint txId, address buyer, address seller, string item, uint price);

	// The sale was completed successfully (item shipped and received by the buyer, payment released to the seller)
	event SaleCompleted(uint txId, address buyer, address seller, string item, uint price);

	// Buy/sell transactions, mapped by Transaction.id
	mapping(uint => Transaction) private transactions;

	// Statistics
	uint private activeTransactions = 0;
	uint private completedTransactions = 0;

	// Transaction ID generator
	uint private lastTransactionId = 0;

	// Called by the buyer
	// TODO Look up item data from an inventory in the buyer's webapp
	function purchaseItem(address seller, string memory item) public payable returns (uint) {
		console2.log("Request to purchase item '%s': buyer = %s", item, msg.sender);
		Transaction memory newTransaction = beginTransaction(msg.sender, seller, item, msg.value);
		// TODO Watch for this event in the seller's webapp
		// https://docs.scaffoldeth.io/hooks/useScaffoldWatchContractEvent
		emit ItemPurchased(newTransaction.id, newTransaction.buyer, newTransaction.seller, newTransaction.item, newTransaction.price);
		return newTransaction.id;
	}

	// Called by the seller
	function shipItem(uint txId) public {
		require(msg.sender == transactions[txId].seller, "Not the seller");
		console2.log("Item shipped: '%s'", transactions[txId].item);
		transactions[txId].status = Status.SHIPPED;
	}

	// Called by the buyer
	function itemReceived(uint txId) public {
		require(msg.sender == transactions[txId].buyer, "Not the buyer");
		console2.log("Item received: '%s'", transactions[txId].item);
		completeTransaction(txId, Status.RECEIVED);

		Transaction memory transaction = transactions[txId];
		(bool success, ) = transaction.seller.call{ value: transaction.price }("");
		require(success, "Failed to send Ether");
		console2.log("Payment released to seller %s", transaction.seller);
	}

	// Called by the buyer
	function cancelPurchase(uint txId) public {
		require(msg.sender == transactions[txId].buyer, "Not the buyer");
		console2.log("Transaction canceled: '%s'", transactions[txId].item);
		completeTransaction(txId, Status.CANCELED);

		Transaction memory transaction = transactions[txId];
		(bool success, ) = transaction.buyer.call{ value: transaction.price }("");
		require(success, "Failed to send Ether");
		console2.log("Payment refunded to buyer %s", transaction.buyer);
	}

	// returns the transactionId
	function beginTransaction(address buyer, address seller, string memory item, uint price) private returns (Transaction memory) {
		Transaction memory newTransaction = Transaction(++lastTransactionId, buyer, seller, item, price, Status.PURCHASED);
		transactions[newTransaction.id] = newTransaction;
		++activeTransactions;
		return newTransaction;
	}

	function completeTransaction(uint txId, Status finalStatus) private {
		transactions[txId].status = finalStatus;
		--activeTransactions;
		++completedTransactions;
		if (Status.RECEIVED == finalStatus) {
			emit SaleCompleted(txId, transactions[txId].buyer, transactions[txId].seller, transactions[txId].item, transactions[txId].price);
		}
	}

	function checkTransactionStatus(uint txId) public view returns (Status) {
		Transaction memory transaction = transactions[txId];
		console2.log("Item '%s': status = %s", transaction.item, statusToString(transaction.status));
		return transaction.status;
	}

	function numActiveTransactions() public view returns (uint) {
		return activeTransactions;
	}

	function numCompletedTransactions() public view returns (uint) {
		return completedTransactions;
	}

	function totalInEscrow() public view returns (uint) {
		return address(this).balance;
	}

	function lastTransaction() public view returns (Transaction memory) {
		return transactions[lastTransactionId];
	}

	function statusToString(Status status) private pure returns (string memory) {
		if (status == Status.PURCHASED) {
			return "PURCHASED";
		} else if (status == Status.SHIPPED) {
			return "SHIPPED";
		} else if (status == Status.RECEIVED) {
			return "RECEIVED";
		} else if (status == Status.CANCELED) {
			return "CANCELED";
		} else {
			return "UNKNOWN";
		}
	}

	constructor() {}

	receive() external payable {}
	fallback() external payable {}
}
