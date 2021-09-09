//
//  ChatClientManager.swift
//  ChatClientManager
//
//  Created by Martin Young on 9/9/21.
//  Copyright © 2021 Benjamin Dodgson. All rights reserved.
//

import Foundation
import Parse
import Combine
import StreamChat

extension ChatClient {

    static var shared: ChatClient!

    static var isConnected: Bool {
        guard let sharedClient = self.shared else { return false }
        return sharedClient.connectionStatus == .connected
    }

    static func initialize(withToken token: String) async throws {
        let config = ChatClientConfig(apiKey: .init("hvmd2mhxcres"))
        // userID: martinjibber
        let token = Token(stringLiteral: token)

        /// create an instance of ChatClient and share it using the singleton
        self.shared = ChatClient(config: config)

        /// connect to chat
        return try await withCheckedThrowingContinuation { continuation in
            self.shared.connectUser(
                userInfo: UserInfo(
                    id: "SpecialID",
                    name: "Martin Jibber",
                    imageURL: URL(string: "https://bit.ly/2TIt8NR")
                ),
                token: token,
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
