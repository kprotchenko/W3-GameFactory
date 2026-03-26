// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import "@openzeppelin/contracts/proxy/utils/Initializable.sol";

contract GameOfChance is Initializable {
    enum Phase {
        Commit,
        Reveal,
        Settled
    }

    address public factory;
    uint256 public lobbyId;

    address public playerA;
    address public playerB;

    uint96 public stake; // per-player stake
    uint40 public commitDeadline;
    uint40 public revealDeadline;
    uint32 public revealDuration;

    Phase public phase;

    bytes32 public commitA;
    bytes32 public commitB;
    bool public committedA;
    bool public committedB;

    bytes32 public saltA;
    bytes32 public saltB;
    bool public revealedA;
    bool public revealedB;

    address public winner;
    uint256 public randomness;

    mapping(address => uint256) public claimable;

    event GameInitialized(
        uint256 indexed lobbyId, address indexed playerA, address indexed playerB, uint96 stake, uint40 commitDeadline
    );

    event Committed(address indexed player, bytes32 commitment);
    event RevealPhaseStarted(uint40 revealDeadline);
    event Revealed(address indexed player, bytes32 salt);

    event Settled(address indexed winner, uint256 amount, uint256 randomness);

    event Refunded(address indexed player, uint256 amount);
    event Withdrawal(address indexed user, uint256 amount);

    constructor() {
        _disableInitializers();
    }

    modifier onlyPlayer() {
        require(msg.sender == playerA || msg.sender == playerB, "not player");
        _;
    }

    function initialize(
        uint256 lobbyId_,
        address playerA_,
        address playerB_,
        uint96 stake_,
        uint32 commitDuration_,
        uint32 revealDuration_
    ) external payable initializer {
        require(playerA_ != address(0) && playerB_ != address(0), "zero player");
        require(playerA_ != playerB_, "same player");
        require(stake_ > 0, "stake = 0");
        require(commitDuration_ > 0, "commitDuration = 0");
        require(revealDuration_ > 0, "revealDuration = 0");
        require(msg.value == uint256(stake_) * 2, "bad funding");

        factory = msg.sender;
        lobbyId = lobbyId_;

        playerA = playerA_;
        playerB = playerB_;

        stake = stake_;
        commitDeadline = uint40(block.timestamp + uint256(commitDuration_));
        revealDuration = revealDuration_;

        phase = Phase.Commit;

        emit GameInitialized(lobbyId_, playerA_, playerB_, stake_, commitDeadline);
    }

    function commitmentFor(address player, bytes32 salt) public view returns (bytes32) {
        return keccak256(abi.encode(address(this), player, salt));
    }

    function commit(bytes32 commitment) external onlyPlayer {
        require(phase == Phase.Commit, "not commit phase");
        require(block.timestamp <= commitDeadline, "commit phase over");

        if (msg.sender == playerA) {
            require(!committedA, "playerA already committed");
            commitA = commitment;
            committedA = true;
        } else {
            require(!committedB, "playerB already committed");
            commitB = commitment;
            committedB = true;
        }

        emit Committed(msg.sender, commitment);

        if (committedA && committedB) {
            phase = Phase.Reveal;
            revealDeadline = uint40(block.timestamp + uint256(revealDuration));
            emit RevealPhaseStarted(revealDeadline);
        }
    }

    function reveal(bytes32 salt) external onlyPlayer {
        require(phase == Phase.Reveal, "not reveal phase");
        require(block.timestamp <= revealDeadline, "reveal phase over");

        if (msg.sender == playerA) {
            require(committedA, "playerA did not commit");
            require(!revealedA, "playerA already revealed");
            require(commitA == commitmentFor(msg.sender, salt), "bad reveal A");

            saltA = salt;
            revealedA = true;
        } else {
            require(committedB, "playerB did not commit");
            require(!revealedB, "playerB already revealed");
            require(commitB == commitmentFor(msg.sender, salt), "bad reveal B");

            saltB = salt;
            revealedB = true;
        }

        emit Revealed(msg.sender, salt);

        if (revealedA && revealedB) {
            _settleWithBothReveals();
        }
    }

    function finalize() external {
        require(phase != Phase.Settled, "already settled");

        if (phase == Phase.Commit) {
            require(block.timestamp > commitDeadline, "commit still active");

            if (committedA && !committedB) {
                _awardWholePot(playerA);
                return;
            }

            if (!committedA && committedB) {
                _awardWholePot(playerB);
                return;
            }

            _refundBoth();
            return;
        }

        // Reveal phase
        if (revealedA && revealedB) {
            _settleWithBothReveals();
            return;
        }

        require(block.timestamp > revealDeadline, "reveal still active");

        if (revealedA && !revealedB) {
            _awardWholePot(playerA);
            return;
        }

        if (!revealedA && revealedB) {
            _awardWholePot(playerB);
            return;
        }

        _refundBoth();
    }

    function withdraw() external {
        uint256 amount = claimable[msg.sender];
        require(amount > 0, "nothing to withdraw");

        claimable[msg.sender] = 0;

        (bool ok,) = payable(msg.sender).call{ value: amount }("");
        require(ok, "transfer failed");

        emit Withdrawal(msg.sender, amount);
    }

    function _settleWithBothReveals() internal {
        require(phase != Phase.Settled, "already settled");

        randomness = uint256(keccak256(abi.encode(saltA, saltB)));
        winner = (randomness & 1 == 0) ? playerA : playerB;

        claimable[winner] += uint256(stake) * 2;
        phase = Phase.Settled;

        emit Settled(winner, uint256(stake) * 2, randomness);
    }

    function _awardWholePot(address who) internal {
        winner = who;
        claimable[who] += uint256(stake) * 2;
        phase = Phase.Settled;

        emit Settled(who, uint256(stake) * 2, 0);
    }

    function _refundBoth() internal {
        claimable[playerA] += uint256(stake);
        claimable[playerB] += uint256(stake);
        phase = Phase.Settled;

        emit Refunded(playerA, uint256(stake));
        emit Refunded(playerB, uint256(stake));
    }
}
