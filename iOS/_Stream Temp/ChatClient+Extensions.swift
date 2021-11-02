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

    /// A shared chat client singleton.
    static var shared: ChatClient!

    /// Returns true if the shared client is connected to the chat service.
    static var isConnected: Bool {
        guard let sharedClient = self.shared else { return false }
        return sharedClient.connectionStatus == .connected
    }

    /// Initializes the shared chat client singleton.
    static func initialize(for user: User) async throws {
        // Create a shared chat client object if needed
        if self.shared.isNil {
            var config = ChatClientConfig(apiKey: .init("hvmd2mhxcres"))
            config.applicationGroupIdentifier = Config.shared.environment.groudID
            config.isLocalStorageEnabled = true 
            self.shared = ChatClient(config: config, tokenProvider: { completion in
                let token = Token.development(userId: user.userObjectID!)
                completion(.success(token))
            })
        }

        let token = Token.development(userId: user.userObjectID!)
        let userId = User.current()?.userObjectID ?? String() as UserId
        var userInfo = UserInfo(id: userId, name: nil, imageURL: nil, extraData: [:])
        #if IOS
        userInfo = UserInfo(id: userId,
                            name: User.current()?.fullName,
                            imageURL: User.current()?.smallImage?.url,
                            extraData: [:])
        #endif

        /// connect to chat
        return try await withCheckedThrowingContinuation { continuation in
            ChatClient.shared.connectUser(
                userInfo: userInfo,
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

    /// Returns a ChatChannelListController synchronized using the provided query.
    func queryChannels(query: ChannelListQuery) async throws -> ChatChannelListController {
        let controller = self.channelListController(query: query)
        return try await withCheckedThrowingContinuation({ continuation in
            controller.synchronize { error in
                if let e = error {
                    continuation.resume(throwing: e)
                } else {
                    continuation.resume(returning: controller)
                }
            }
        })
    }

    /// Returns a ChatChannelMemberListController synchronized with the members requested with the query.
    func queryMembers(query: ChannelMemberListQuery) async throws -> ChatChannelMemberListController {
        let controller = self.memberListController(query: query)
        return try await withCheckedThrowingContinuation({ continuation in
            controller.synchronize { error in
                if let e = error {
                    continuation.resume(throwing: e)
                } else {
                    continuation.resume(returning: controller)
                }
            }
        })
    }

    /// Deletes the specified channel.
    func deleteChannel(_ channel: ChatChannel) async throws {
        let controller = self.channelController(for: channel.cid)
        return try await withCheckedThrowingContinuation({ continuation in
            controller.deleteChannel { error in
                if let e = error {
                    continuation.resume(throwing: e)
                } else {
                    continuation.resume(returning: ())
                }
            }
        })
    }
}
