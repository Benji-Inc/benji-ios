//
//  new_ChatClientManager.swift
//  new_ChatClientManager
//
//  Created by Martin Young on 9/9/21.
//  Copyright © 2021 Benjamin Dodgson. All rights reserved.
//

import Foundation
import Parse
import Combine
import StreamChat

class new_ChatClientManager: NSObject {

    static let shared = new_ChatClientManager()
    var client: ChatClient!

    //    @Published var clientSyncUpdate: TCHClientSynchronizationStatus? = nil
    //    @Published var clientUpdate: ChatClientUpdate? = nil
    //    @Published var conversationSyncUpdate: ConversationSyncUpdate? = nil
    //    @Published var conversationsUpdate: ConversationUpdate? = nil
    //    @Published var messageUpdate: MessageUpdate? = nil
    //    @Published var memberUpdate: ConversationMemberUpdate? = nil

    var isConnected: Bool {
        guard let client = self.client else { return false }
        return client.connectionStatus == .connected
    }

    func initialize() async throws {
        let config = ChatClientConfig(apiKey: .init("hvmd2mhxcres"))
        // userID: martinjibber
        // secret: 6bymtfbe6udf8aa3gsdp5r47ysz4cu8rvqnwc5r5cg9vtd898r3akzwxgjz5qfbq
        let streamToken = Token(
            stringLiteral: "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VyX2lkIjoibWFydGluamliYmVyIn0.3gkQkf_oBGylx79R3GMvtUEXC74k5WB2epE23COPZdo"
        )

        /// create an instance of ChatClient and share it using the singleton
        self.client = ChatClient(config: config)

        /// connect to chat
        return try await withCheckedThrowingContinuation { continuation in
            self.client.connectUser(
                userInfo: UserInfo(
                    id: "tutorial-droid",
                    name: "Tutorial Droid",
                    imageURL: URL(string: "https://bit.ly/2TIt8NR")
                ),
                token: streamToken,
                completion: { error in
                    if let error = error {
                        continuation.resume(throwing: error)
                    } else {
                        continuation.resume(returning: ())
                    }
                }
            )
        }
    }
}
