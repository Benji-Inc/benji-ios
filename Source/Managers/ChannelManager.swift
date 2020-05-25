//
//  ChannelManager.swift
//  Benji
//
//  Created by Benji Dodgson on 1/29/19.
//  Copyright © 2019 Benjamin Dodgson. All rights reserved.
//

import Foundation
import TwilioChatClient
import ReactiveSwift
import Parse
import TMROFutures

class ChannelManager: NSObject {

    static let shared = ChannelManager()
    private(set) var client: TwilioChatClient?

    var clientSyncUpdate = MutableProperty<TCHClientSynchronizationStatus?>(nil)
    var clientUpdate = MutableProperty<ChatClientUpdate?>(nil)
    var channelSyncUpdate = MutableProperty<ChannelSyncUpdate?>(nil)
    var channelsUpdate = MutableProperty<ChannelUpdate?>(nil)
    var messageUpdate = MutableProperty<MessageUpdate?>(nil)
    var memberUpdate = MutableProperty<ChannelMemberUpdate?>(nil)

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

    deinit {
        self.client?.shutdown() // This was recommended in the docs.
    }

    func initialize(token: String) -> Future<Void> {
        let promise = Promise<Void>()
        TwilioChatClient.chatClient(withToken: token,
                                    properties: nil,
                                    delegate: self,
                                    completion: { (result, client) in

                                        if let error = result.error {
                                            promise.reject(with: error)
                                        } else if let strongClient = client {
                                            self.client = strongClient
                                            promise.resolve(with: ())
                                        } else {
                                            promise.reject(with: ClientError.message(detail: "Failed to initialize chat client."))
                                        }
        })
        
        return promise.withResultToast(with: "Messaging Enabled.")
    }

    func update(token: String, completion: @escaping CompletionHandler) {
        guard let client = self.client else { return }
        client.updateToken(token, completion: { (result) in
            completion(true, nil)
        })
    }
}
