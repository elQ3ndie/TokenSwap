// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract TokenSwap {
    uint256 orderCount;

    struct Order {
        uint256 orderId;
        address depositor;
        address depositToken;
        uint256 depositAmount;
        address desiredToken;
        uint256 desiredAmount;
        bool isCompleted;
    }

    mapping(uint256 => Order) public orders;

    event OrderCreated(
        uint256 orderId,
        address depositor,
        address depositToken,
        uint256 depositAmount,
        address desiredToken,
        uint256 desiredAmount
    );
    event OrderFulfilled(uint256 orderId, address fulfiller);

    function createOrder(
        address _depositToken,
        uint256 _depositAmount,
        address _desiredToken,
        uint256 _desiredAmount
    ) external {
        require(msg.sender != address(0), "Address zero detected");
        require(_depositAmount > 0, "Zero deposits not allowed");
        require(
            IERC20(_depositToken).balanceOf(msg.sender) >= _depositAmount,
            "Insufficient Funds"
        );
        require(
            IERC20(_depositToken).allowance(msg.sender, address(this)) >=
                _depositAmount,
            "Insufficient allowance"
        );

        // Transfer the deposit tokens to the contract
        IERC20(_depositToken).transferFrom(
            msg.sender,
            address(this),
            _depositAmount
        );

        orderCount += 1;

        Order storage newOrder = orders[orderCount];
        newOrder.orderId = orderCount;
        newOrder.depositor = msg.sender;
        newOrder.depositToken = _depositToken;
        newOrder.depositAmount = _depositAmount;
        newOrder.desiredToken = _desiredToken;
        newOrder.desiredAmount = _desiredAmount;

        emit OrderCreated(
            orderCount,
            msg.sender,
            _depositToken,
            _depositAmount,
            _desiredToken,
            _desiredAmount
        );
    }

    function fulfillOrder(uint _orderId) external {
        Order storage order = orders[_orderId];

        require(msg.sender != address(0), "Address zero detected");
        require(_orderId != 0, "OrderId must be greater than zero");
        require(_orderId <= orderCount, "Order does not exist");
        require(!order.isCompleted, "Order has been completed");

        require(
            IERC20(order.desiredToken).balanceOf(msg.sender) >=
                order.desiredAmount,
            "Insufficient funds"
        );
        require(
            IERC20(order.desiredToken).allowance(msg.sender, address(this)) >=
                order.desiredAmount,
            "Insufficient allowance"
        );

        // Transfer the fulfiller's tokens to the depositor
        IERC20(order.desiredToken).transferFrom(
            msg.sender,
            order.depositor,
            order.desiredAmount
        );

        // Transfer the depositor's tokens to the fulfiller
        IERC20(order.depositToken).transfer(msg.sender, order.depositAmount);

        order.isCompleted = true;

        emit OrderFulfilled(_orderId, msg.sender);
    }
}
