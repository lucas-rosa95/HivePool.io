// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.20;

contract Owned {
    address payable owner;
    constructor() {
        owner = payable(msg.sender);
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }
}

contract Freezable is Owned {
    bool private _frozen = false;

    modifier notFrozen() {
        require(!_frozen, "Inactive Contract.");
        _;
    }

    function freeze() internal {
        if (msg.sender == owner) _frozen = true;
    }
}

contract HivePool is Freezable {
    uint256 private currentFee;
    uint256 private limitParticipants;
    uint256 private lastHiveId = 100000;

    error InvalidDeposit();
    error InvalidLimitParticipants();
    error InvalidSubscriptionPeriod();

    uint256 constant MIN_DEPOSIT = 0.01 ether;
    uint256 constant MAX_DEPOSIT = 100 ether;
    uint256 constant MAX_PARTICIPANTS = 100;

    event HiveCreated(uint256 hiveId);

    enum RewardPeriod {
        Weekly,
        Monthly
    }

    enum HiveStatus {
        Closed,
        Created,
        Canceled
    }

    struct HiveStruct {
        uint256 id;
        address creator;
        uint256 limitParticipants;
        uint256 startSubscription;
        uint256 endSubscription;
        uint256 entryAmount;
        uint256 totalAmount;
        HiveStatus status;
        RewardPeriod rewardPeriod;
        uint256 rewardPaid;
        uint256 applitedFee;
    }

    mapping(uint256 => HiveStruct) public hives;

    constructor(uint256 _fee, uint256 _limitParticipants) payable {
        currentFee = _fee;
        limitParticipants = _limitParticipants;
    }

    function shutdown() external onlyOwner notFrozen {
        freeze();
        payable(msg.sender).transfer(address(this).balance);
    }

    function getCurrentFee() external view returns (uint256) {
        return currentFee;
    }

    function modifyFee(uint256 _fee) external onlyOwner {
        currentFee = _fee;
    }

    function getLimitsParticipants() external view onlyOwner returns (uint256) {
        return limitParticipants;
    }

    function modifyLimitParticipants(
        uint256 _limitParticipants
    ) external onlyOwner {
        limitParticipants = _limitParticipants;
    }

    function createHive(
        uint256 _startSubscription,
        uint256 _endSubscription,
        RewardPeriod _rewardPeriod,
        uint256 _limitParticipants
    ) external payable returns (uint256) {
        if (msg.value < MIN_DEPOSIT || msg.value > MAX_DEPOSIT)
            revert InvalidDeposit();

        if (
            _startSubscription < block.timestamp ||
            _endSubscription < _startSubscription + 7 days
        ) revert InvalidSubscriptionPeriod();

        if (_limitParticipants > MAX_PARTICIPANTS)
            revert InvalidLimitParticipants();

        hives[++lastHiveId] = HiveStruct({
            id: lastHiveId,
            creator: msg.sender,
            totalAmount: msg.value,
            entryAmount: msg.value,
            status: HiveStatus.Created,
            rewardPeriod: _rewardPeriod,
            limitParticipants: _limitParticipants,
            startSubscription: _startSubscription,
            endSubscription: _endSubscription,
            applitedFee: 0,
            rewardPaid: 0
        });

        emit HiveCreated(lastHiveId);

        return lastHiveId;
    }
}
