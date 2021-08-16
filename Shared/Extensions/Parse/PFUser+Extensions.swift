//
//  PFUser+Extensions.swift
//  PFUser+Extensions
//
//  Created by Martin Young on 8/15/21.
//  Copyright © 2021 Benjamin Dodgson. All rights reserved.
//

import Foundation
import Parse

extension PFUser {

    @discardableResult
    static func become(asynchronously sessionToken: String) async throws -> PFUser {
        let user: PFUser = try await withCheckedThrowingContinuation { continuation in
            User.become(inBackground: sessionToken) { (user, error) in
                if let user = user {
                    return continuation.resume(returning: user)
                } else if let error = error {
                    return continuation.resume(throwing: error)
                } else {
                    return continuation.resume(throwing: ClientError.apiError(detail: "Failed to become user."))
                }
            }
        }

#if !NOTIFICATION
        await UserNotificationManager.shared.silentRegister(withApplication: UIApplication.shared)
#endif
        return user
    }
}
