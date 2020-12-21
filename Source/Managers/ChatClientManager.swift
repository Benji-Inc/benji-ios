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
}
