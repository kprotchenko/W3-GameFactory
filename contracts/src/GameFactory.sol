// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {GameOfChance} from "../src/GameOfChance.sol"

contract GameFactory {
    enum LobbyStatus {
        Open,
        Matched,
        Cancelled,
        Expired
    }

    struct Lobby {
        address creator;
        address invitedOpponent; // address(0) => public lobby
        address game; // clone address once matched
        uint96 stake; // per-player stake
        uint40 joinDeadline;
        uint32 commitDuration;
        uint32 revealDuration;
        LobbyStatus status;
    }

    address public immutable implementation;
    uint256 public nextLobbyId;

    mapping(uint256 => Lobby) public lobbies;
    mapping(address => uint256) public claimable;

    event LobbyCreated(
        uint256 indexed lobbyId,
        address indexed creator,
        address indexed invitedOpponent,
        uint96 stake,
        uint40 joinDeadline,
        uint32 commitDuration,
        uint32 revealDuration
    );

    event LobbyJoined(uint256 indexed lobbyId, address indexed joiner, address indexed game);

    event LobbyCancelled(uint256 indexed lobbyId);
    event LobbyExpired(uint256 indexed lobbyId);
    event FactoryWithdrawal(address indexed user, uint256 amount);

    constructor() {
        implementation = address(new GameOfChance());
    }

    function createLobby(address invitedOpponent, uint32 joinDuration, uint32 commitDuration, uint32 revealDuration)
        external
        payable
        returns (uint256 lobbyId)
    {
        require(msg.value > 0, "stake = 0");
        require(msg.value <= type(uint96).max, "stake too large");
        require(joinDuration > 0, "joinDuration = 0");
        require(commitDuration > 0, "commitDuration = 0");
        require(revealDuration > 0, "revealDuration = 0");

        lobbyId = nextLobbyId++;
        uint40 joinDeadline = uint40(block.timestamp + uint256(joinDuration));

        lobbies[lobbyId] = Lobby({
            creator: msg.sender,
            invitedOpponent: invitedOpponent,
            game: address(0),
            stake: uint96(msg.value),
            joinDeadline: joinDeadline,
            commitDuration: commitDuration,
            revealDuration: revealDuration,
            status: LobbyStatus.Open
        });

        emit LobbyCreated(
            lobbyId, msg.sender, invitedOpponent, uint96(msg.value), joinDeadline, commitDuration, revealDuration
        );
    }

    function joinLobby(uint256 lobbyId) external payable returns (address game) {
        Lobby storage lobby = lobbies[lobbyId];

        require(lobby.status == LobbyStatus.Open, "lobby not open");
        require(block.timestamp <= lobby.joinDeadline, "join phase over");
        require(msg.sender != lobby.creator, "creator cannot join own lobby");
        require(msg.value == uint256(lobby.stake), "wrong stake");

        if (lobby.invitedOpponent != address(0)) {
            require(msg.sender == lobby.invitedOpponent, "not invited");
        }

        game = Clones.clone(implementation);

        uint256 totalPot = uint256(lobby.stake) + msg.value;

        GameOfChance(payable(game)).initialize{ value: totalPot }(
            lobbyId, lobby.creator, msg.sender, lobby.stake, lobby.commitDuration, lobby.revealDuration
        );

        lobby.game = game;
        lobby.status = LobbyStatus.Matched;

        emit LobbyJoined(lobbyId, msg.sender, game);
    }

    function cancelLobby(uint256 lobbyId) external {
        Lobby storage lobby = lobbies[lobbyId];

        require(lobby.status == LobbyStatus.Open, "lobby not open");
        require(msg.sender == lobby.creator, "not creator");

        lobby.status = LobbyStatus.Cancelled;
        claimable[lobby.creator] += uint256(lobby.stake);

        emit LobbyCancelled(lobbyId);
    }

    function expireLobby(uint256 lobbyId) external {
        Lobby storage lobby = lobbies[lobbyId];

        require(lobby.status == LobbyStatus.Open, "lobby not open");
        require(block.timestamp > lobby.joinDeadline, "join still active");

        lobby.status = LobbyStatus.Expired;
        claimable[lobby.creator] += uint256(lobby.stake);

        emit LobbyExpired(lobbyId);
    }

    function withdrawFactoryCredit() external {
        uint256 amount = claimable[msg.sender];
        require(amount > 0, "nothing to withdraw");

        claimable[msg.sender] = 0;

        (bool ok,) = payable(msg.sender).call{ value: amount }("");
        require(ok, "transfer failed");

        emit FactoryWithdrawal(msg.sender, amount);
    }
}
