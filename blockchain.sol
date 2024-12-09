// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

contract Escrov {
    address public buyer;
    address public seller;
    address public arbiter;
    uint256 public amount;

    enum State {
        AWAITING_PAYMENT,
        AWAITING_DELIVERY,
        COMPLETE,
        DISPUTED
    }

    State public currentState;

    modifier onlyBuyer() {
        require(msg.sender == buyer , "Only the buyer can perform this action.");
        _;
    }

    modifier onlyArbiter() {
        require(msg.sender == arbiter , "Only the arbiter can resolve disputes.");
        _;
    }

    event PaymentDeposited(address buyer, uint256 amount);
    event DeliveryConfirmed(address buyer);
    event PaymentReleased(address seller, uint256 amount);
    event DisputeResolved(string decision);

    constructor(address _seller, address _arbiter) {
        buyer = msg.sender;
        seller = _seller;
        arbiter = _arbiter;
        currentState = State.AWAITING_PAYMENT;
    }

    // Buyer deposits payment
    function depositPayment() public payable onlyBuyer() {
        require(currentState == State.AWAITING_PAYMENT, "Payment has already been made.");
        
        amount = msg.value;
        currentState = State.AWAITING_DELIVERY;

        emit PaymentDeposited(buyer, msg.value);
    }

    // Buyer vonfirms delivery
    function confirmDelivery() public onlyBuyer {
        require(currentState == State.AWAITING_DELIVERY, "Delivery is not yet awaited.");
        currentState = State.COMPLETE;

        // Realese payment to seller
        (bool success, ) = seller.call{value: amount}("");
        require(success, "Payment release failed");

        emit DeliveryConfirmed(buyer);
        emit PaymentReleased(seller, amount);
    }

    // Raise a dispute
    function raiseDispute() public onlyBuyer {
        require(currentState == State.AWAITING_DELIVERY, "Disputes can only be raise during delivery");
        currentState = State.DISPUTED;
    }

    // Arbiter resolves the disputes
    function resolveDispute(bool releaseToSeller) public onlyArbiter {
        require(currentState == State.DISPUTED, " No dispute to fesolve");

        if(releaseToSeller) {
            // Funds go to the seller
            (bool success, ) = seller.call{value: amount}("");
            require(success, "Payment realse to seller failed");
            emit DisputeResolved("Funds reales to seller.");
        }else {
            // Refund to the Buyer
            (bool success, ) = buyer.call{value: amount}("");
            require(success, "Refund to buyer Failed");
            emit DisputeResolved("Funds refunded yo buyer");
        }

        currentState = State.COMPLETE;
    }

    //Get current contact balance (for transparency)
    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }
}