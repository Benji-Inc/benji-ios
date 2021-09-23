//
//  LaunchManager+Extensions.swift
//  Jibber
//
//  Created by Benji Dodgson on 9/23/21.
//  Copyright © 2021 Benjamin Dodgson. All rights reserved.
//

import Foundation
import StreamChat

extension LaunchManager {

#if !APPCLIP && !NOTIFICATION
    func getChatToken(for user: User, deepLink: DeepLinkable?) async -> LaunchStatus {
        // No need to get a new chat token if we're already connected.
        guard !ChatClient.isConnected else {
            return .success(object: deepLink)
        }

        do {
            try await ChatClient.initialize(for: user)

            self.finishedInitialFetch = true
            return .success(object: deepLink)
        } catch {
            return .failed(error: ClientError.apiError(detail: error.localizedDescription))
        }
    }
#endif
}
