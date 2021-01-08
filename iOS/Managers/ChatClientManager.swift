//
//  ChannelManager.swift
//  Benji
//
//  Created by Benji Dodgson on 1/29/19.
//  Copyright © 2019 Benjamin Dodgson. All rights reserved.
//

import Foundation
import TwilioChatClient
import Parse
import Combine

class ChatClientManager: NSObject {

    static let shared = ChatClientManager()
    var client: TwilioChatClient?

    @Published var clientSyncUpdate: TCHClientSynchronizationStatus? = nil
    @Published var clientUpdate: ChatClientUpdate? = nil
    @Published var channelSyncUpdate: ChannelSyncUpdate? = nil
    @Published var channelsUpdate: ChannelUpdate? = nil
    @Published var messageUpdate: MessageUpdate? = nil
    @Published var memberUpdate: ChannelMemberUpdate? = nil

    var isSynced: Bool {
        guard let client = self.client else { return false }
        if client.synchronizationStatus == .completed || client.synchronizationStatus == .channelsListCompleted {
            return true
        }

        return false
    }

    var isConnected: Bool {
        guard let client = self.client else { return false }
        return client.connectionState == .connected
    }

    var cancellables = Set<AnyCancellable>()

    @discardableResult
    func initialize(token: String) -> Future<Void, Error> {
        return Future { [weak self] promise in
            guard let `self` = self else { return }
            // Initialize the ChannelSupplier so it can listen to the client updates.
            _ = ChannelSupplier.shared
            TwilioChatClient.chatClient(withToken: token,
                                        properties: nil,
                                        delegate: self,
                                        completion: { (result, client) in

                                            if let error = result.error {
                                                promise(.failure(error))
                                            } else if let strongClient = client {
                                                self.client = strongClient
                                                //TwilioChatClient.setLogLevel(.debug)
                                                promise(.success(()))
                                            } else {
                                                promise(.failure(ClientError.message(detail: "Failed to initialize chat client.")))
                                            }
            })
        }
    }

    @discardableResult
    func update(token: String) -> Future<Void, Error> {
        return Future { promise in
            if let client = self.client {
                client.updateToken(token, completion: { (result) in
                    if result.isSuccessful() {
                        promise(.success(()))
                    } else if let e = result.error {
                        promise(.failure(e))
                    } else {
                        promise(.failure(ClientError.message(detail: "Failed to update chat token.")))
                    }
                })
            }
        }
    }
}
