//
//  PFInstallation+Extensions.swift
//  Benji
//
//  Created by Benji Dodgson on 1/26/20.
//  Copyright © 2020 Benjamin Dodgson. All rights reserved.
//

import Foundation
import Parse

extension PFInstallation {

    static func getCurrent() async throws -> PFInstallation {
        let installation: PFInstallation = try await withCheckedThrowingContinuation { continuation in
            self.getCurrentInstallationInBackground().continueWith { task in
                do {
                    try Task.checkCancellation()
                } catch {
                    return continuation.resume(throwing: error)
                }

                if let installation = task.result {
                    return continuation.resume(returning: installation)
                } else {
                    return continuation.resume(throwing: ClientError.apiError(detail: "No installation was returned"))
                }
            }
        }

        return installation
    }
}
