//
//  InitialConversation.swift
//  Jibber
//
//  Created by Benji Dodgson on 11/13/21.
//  Copyright © 2021 Benjamin Dodgson. All rights reserved.
//

import Foundation
import ParseSwift

enum InitialConversationKey: String {
    case conversationId
}

/// Used to store a conversation that was created by coming in off a Pass or Reservation. Only to be stored locally in shared container that can accessed by the AppClip and the App
struct InitialConveration: ParseObject, ParseObjectMutable {
    
    //: These are required by `ParseObject`.
    var objectId: String?
    var createdAt: Date?
    var updatedAt: Date?
    var ACL: ParseACL?
    
    var conversationId: String?
    
    //    func saveLocally() async throws {
    //        return try await withCheckedThrowingContinuation { continuation in
    //            self.pinInBackground(withName: "InitialConveration") { success, error in
    //                if let e = error {
    //                    continuation.resume(throwing: e)
    //                } else {
    //                    continuation.resume(returning: ())
    //                }
    //            }
    //        }
    //    }
    //
    //    static func retrieve() async throws -> InitialConveration {
    //        return try await withCheckedThrowingContinuation({ continuation in
    //            let query = InitialConveration.query()
    //            query?.fromPin(withName: "InitialConveration")
    //            query?.getFirstObjectInBackground(block: { object, error in
    //                if let initial = object as? InitialConveration {
    //                    initial.unpinInBackground { result, error in
    //                        if let e = error {
    //                            continuation.resume(throwing: e)
    //                        } else {
    //                            continuation.resume(returning: initial)
    //                        }
    //                    }
    //                } else if let e = error {
    //                    continuation.resume(throwing: e)
    //                } else {
    //                    continuation.resume(throwing: ClientError.generic)
    //                }
    //            })
    //        })
    //    }
}
