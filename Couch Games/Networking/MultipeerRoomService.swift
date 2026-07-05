//
//  MultipeerRoomService.swift
//  Couch Games
//

import Foundation
import MultipeerConnectivity

@MainActor
@Observable
final class MultipeerRoomService: NSObject {
    static let serviceType = "couch-games"

    private(set) var isHost = false
    private(set) var isConnected = false
    private(set) var gameKind: ConnectedGameKind?
    private(set) var players: [RoomPlayer] = []
    private(set) var statusText = "Not connected"
    private(set) var lastMessage: ConnectedMessage?

    var localPlayer: RoomPlayer? {
        players.first { $0.isLocal }
    }

    var canStartGame: Bool {
        isHost && players.count >= (gameKind?.minPlayers ?? 2)
    }

    private var peerID = MCPeerID(displayName: UIDevice.current.name)
    private var session: MCSession?
    private var advertiser: MCNearbyServiceAdvertiser?
    private var browser: MCNearbyServiceBrowser?
    private var hostPlayerID = UUID()
    private var peerNameToPlayerID: [String: UUID] = [:]
    private var joinTargetGame: ConnectedGameKind?
    private var joinInviteSent = false

    var onMessage: ((ConnectedMessage) -> Void)?

    func configureDisplayName(_ name: String) {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        peerID = MCPeerID(displayName: trimmed)
    }

    func hostRoom(game: ConnectedGameKind, displayName: String) {
        stop()
        configureDisplayName(displayName)
        isHost = true
        gameKind = game
        hostPlayerID = UUID()
        peerNameToPlayerID = [peerID.displayName: hostPlayerID]

        let host = RoomPlayer(id: hostPlayerID, name: displayName, isHost: true, isLocal: true)
        players = [host]
        statusText = "Hosting room…"

        let session = MCSession(peer: peerID, securityIdentity: nil, encryptionPreference: .required)
        session.delegate = self
        self.session = session

        let discovery = ["game": game.rawValue]
        advertiser = MCNearbyServiceAdvertiser(peer: peerID, discoveryInfo: discovery, serviceType: Self.serviceType)
        advertiser?.delegate = self
        advertiser?.startAdvertisingPeer()
        isConnected = true
        statusText = "Waiting for players to join"
    }

    func joinNearby(game: ConnectedGameKind, displayName: String) {
        stop()
        configureDisplayName(displayName)
        isHost = false
        joinTargetGame = game
        gameKind = game
        joinInviteSent = false
        players = []
        statusText = "Looking for nearby \(game.title) room…"

        let session = MCSession(peer: peerID, securityIdentity: nil, encryptionPreference: .required)
        session.delegate = self
        self.session = session

        browser = MCNearbyServiceBrowser(peer: peerID, serviceType: Self.serviceType)
        browser?.delegate = self
        browser?.startBrowsingForPeers()
    }

    func startGame() {
        guard isHost, let gameKind else { return }
        let payload = ConnectedGameStartPayload(game: gameKind, players: players, hostPlayerID: hostPlayerID)
        let message = ConnectedMessage.startGame(payload)
        send(message, to: session?.connectedPeers ?? [])
        lastMessage = message
        onMessage?(message)
    }

    func send(_ message: ConnectedMessage, to peers: [MCPeerID]) {
        guard let session, !peers.isEmpty else { return }
        guard let data = try? JSONEncoder().encode(message) else { return }
        try? session.send(data, toPeers: peers, with: .reliable)
    }

    func broadcast(_ message: ConnectedMessage) {
        send(message, to: session?.connectedPeers ?? [])
    }

    func sendToHost(_ message: ConnectedMessage) {
        guard let session, !isHost else { return }
        send(message, to: session.connectedPeers)
    }

    func peerID(for playerID: UUID) -> MCPeerID? {
        guard let session else { return nil }
        guard let entry = peerNameToPlayerID.first(where: { $0.value == playerID }) else { return nil }
        return session.connectedPeers.first { $0.displayName == entry.key }
            ?? (entry.key == peerID.displayName ? peerID : nil)
    }

    func sendToPlayer(_ message: ConnectedMessage, playerID: UUID) {
        if playerID == localPlayer?.id {
            lastMessage = message
            onMessage?(message)
            return
        }
        if let peer = peerID(for: playerID) {
            send(message, to: [peer])
        }
    }

    func playerID(for peer: MCPeerID) -> UUID? {
        peerNameToPlayerID[peer.displayName]
    }

    func stop() {
        advertiser?.stopAdvertisingPeer()
        browser?.stopBrowsingForPeers()
        session?.disconnect()
        advertiser = nil
        browser = nil
        session = nil
        isHost = false
        isConnected = false
        gameKind = nil
        joinTargetGame = nil
        joinInviteSent = false
        players = []
        statusText = "Not connected"
        peerNameToPlayerID = [:]
    }

    private func publishRoster() {
        guard isHost else { return }
        broadcast(.roster(players))
    }

    private func handleIncoming(_ data: Data, from peer: MCPeerID) {
        guard let message = try? JSONDecoder().decode(ConnectedMessage.self, from: data) else { return }
        lastMessage = message
        onMessage?(message)

        switch message {
        case .roster(let roster):
            if !isHost {
                players = roster.map { player in
                    var copy = player
                    copy.isLocal = player.name == peerID.displayName
                    return copy
                }
                statusText = "In room · \(roster.count) players"
            }
        case .startGame(let payload):
            if !isHost {
                players = payload.players
                gameKind = payload.game
                statusText = "Game starting…"
            }
        default:
            break
        }
    }

    private func addGuestPeer(_ peer: MCPeerID) {
        guard isHost else { return }
        guard !peerNameToPlayerID.keys.contains(peer.displayName) else { return }
        let id = UUID()
        peerNameToPlayerID[peer.displayName] = id
        players.append(RoomPlayer(id: id, name: peer.displayName, isHost: false, isLocal: false))
        publishRoster()
        statusText = "\(players.count) players in room"
    }
}

extension MultipeerRoomService: MCNearbyServiceAdvertiserDelegate {
    nonisolated func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didReceiveInvitationFromPeer peerID: MCPeerID, withContext context: Data?, invitationHandler: @escaping (Bool, MCSession?) -> Void) {
        Task { @MainActor in
            invitationHandler(true, self.session)
        }
    }
}

extension MultipeerRoomService: MCNearbyServiceBrowserDelegate {
    nonisolated func browser(_ browser: MCNearbyServiceBrowser, foundPeer peerID: MCPeerID, withDiscoveryInfo info: [String: String]?) {
        Task { @MainActor in
            guard !isHost, let session, let joinTargetGame else { return }
            guard !joinInviteSent, session.connectedPeers.isEmpty else { return }
            guard info?["game"] == joinTargetGame.rawValue else { return }

            joinInviteSent = true
            gameKind = joinTargetGame
            browser.invitePeer(peerID, to: session, withContext: nil, timeout: 12)
            browser.stopBrowsingForPeers()
            statusText = "Joining \(joinTargetGame.title) room…"
        }
    }

    nonisolated func browser(_ browser: MCNearbyServiceBrowser, lostPeer peerID: MCPeerID) {}
}

extension MultipeerRoomService: MCSessionDelegate {
    nonisolated func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
        Task { @MainActor in
            switch state {
            case .connected:
                isConnected = true
                if isHost {
                    addGuestPeer(peerID)
                } else {
                    statusText = "Connected to host"
                }
            case .notConnected:
                if session.connectedPeers.isEmpty {
                    statusText = isHost ? "Waiting for players" : "Disconnected"
                }
            case .connecting:
                statusText = "Connecting…"
            @unknown default:
                break
            }
        }
    }

    nonisolated func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
        Task { @MainActor in
            handleIncoming(data, from: peerID)
        }
    }

    nonisolated func session(_ session: MCSession, didReceive stream: InputStream, withName streamName: String, fromPeer peerID: MCPeerID) {}
    nonisolated func session(_ session: MCSession, didStartReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, with progress: Progress) {}
    nonisolated func session(_ session: MCSession, didFinishReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, at localURL: URL?, withError error: Error?) {}
}

import UIKit
