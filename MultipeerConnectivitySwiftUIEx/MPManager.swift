//
//  MPManager.swift
//  MultipeerConnectivitySwiftUIEx
//
//  Created by Никита Гуляев on 19.08.2024.
//

import MultipeerConnectivity

class MultipeerManager: NSObject, ObservableObject {
    private let myPeerId = MCPeerID(displayName: UIDevice.current.name)
    private let serviceType = "example-chat"

    private var serviceAdvertiser: MCNearbyServiceAdvertiser?
    private var serviceBrowser: MCNearbyServiceBrowser?
    
    @Published var session: MCSession?
    @Published var peers: [MCPeerID] = []
    @Published var receivedMessages: [String] = []
    @Published var isConnected: Bool = false
    @Published var connectionStatus: String = "Not Connected"

    override init() {
        super.init()
        session = MCSession(peer: myPeerId, securityIdentity: nil, encryptionPreference: .required)
        session?.delegate = self

        serviceAdvertiser = MCNearbyServiceAdvertiser(peer: myPeerId, discoveryInfo: nil, serviceType: serviceType)
        serviceAdvertiser?.delegate = self
        serviceAdvertiser?.startAdvertisingPeer()

        serviceBrowser = MCNearbyServiceBrowser(peer: myPeerId, serviceType: serviceType)
        serviceBrowser?.delegate = self
        serviceBrowser?.startBrowsingForPeers()
    }

    func send(message: String) {
        guard let session = session else { return }
        guard !session.connectedPeers.isEmpty else { return }
        if let messageData = message.data(using: .utf8) {
            do {
                try session.send(messageData, toPeers: session.connectedPeers, with: .reliable)
                receivedMessages.append("You: \(message)")
            } catch {
                print("Error sending message: \(error.localizedDescription)")
            }
        }
    }
}

extension MultipeerManager: MCSessionDelegate {
    func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
        DispatchQueue.main.async {
            switch state {
            case .connected:
                self.isConnected = true
                self.connectionStatus = "Connected"
            case .connecting:
                self.connectionStatus = "Connecting"
            case .notConnected:
                self.isConnected = false
                self.connectionStatus = "Not Connected"
            @unknown default:
                fatalError("Unknown state received: \(state)")
            }
        }
    }

    func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
        if let message = String(data: data, encoding: .utf8) {
            DispatchQueue.main.async {
                self.receivedMessages.append("\(peerID.displayName): \(message)")
            }
        }
    }

    // Required empty implementations
    func session(_ session: MCSession, didReceive stream: InputStream, withName streamName: String, fromPeer peerID: MCPeerID) {}
    func session(_ session: MCSession, didStartReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, with progress: Progress) {}
    func session(_ session: MCSession, didFinishReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, at localURL: URL?, withError error: Error?) {}
}

extension MultipeerManager: MCNearbyServiceAdvertiserDelegate {
    func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didReceiveInvitationFromPeer peerID: MCPeerID, withContext context: Data?, invitationHandler: @escaping (Bool, MCSession?) -> Void) {
        invitationHandler(true, session)
    }
}

extension MultipeerManager: MCNearbyServiceBrowserDelegate {
    func browser(_ browser: MCNearbyServiceBrowser, foundPeer peerID: MCPeerID, withDiscoveryInfo info: [String : String]?) {
        guard let session = session else { return }
        peers.append(peerID)
        browser.invitePeer(peerID, to: session, withContext: nil, timeout: 10)
    }

    func browser(_ browser: MCNearbyServiceBrowser, lostPeer peerID: MCPeerID) {
        if let index = peers.firstIndex(of: peerID) {
            peers.remove(at: index)
        }
    }
}
