//
//  ChatClientManager.swift
//  ChatClientManager
//
//  Created by Martin Young on 9/9/21.
//  Copyright © 2021 Benjamin Dodgson. All rights reserved.
//

import Foundation
import StreamChat

extension ChatClient {

    static var shared: ChatClient!

    static var isConnected: Bool {
        guard let sharedClient = self.shared else { return false }
        return sharedClient.connectionStatus == .connected
    }

    static func initialize(for user: User) async throws {
        // Create a shared chat client object if needed
        if self.shared.isNil {
            let config = ChatClientConfig(apiKey: .init("hvmd2mhxcres"))
            self.shared = ChatClient(config: config, tokenProvider: { completion in
                let token = Token.development(userId: user.userObjectID!)
                completion(.success(token))
            })
        }

        let token = Token.development(userId: user.userObjectID!)

        /// connect to chat
        return try await withCheckedThrowingContinuation { continuation in
            self.shared.connectUser(
                userInfo: UserInfo(
                    id: user.userObjectID!,
                    name: user.fullName,
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
