//
//  DataController+Extension.swift
//  DataController+Extension
//
//  Created by Martin Young on 9/9/21.
//  Copyright © 2021 Benjamin Dodgson. All rights reserved.
//

import Foundation
import StreamChat

extension DataController {

    func synchronize() async throws {
        return try await withCheckedThrowingContinuation { continuation in
            self.synchronize { error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: ())
                }
            }
        }
    }
}
