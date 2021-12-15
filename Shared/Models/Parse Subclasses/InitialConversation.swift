//
//  InitialConversation.swift
//  Jibber
//
//  Created by Benji Dodgson on 11/13/21.
//  Copyright © 2021 Benjamin Dodgson. All rights reserved.
//

import Foundation
import Parse

enum InitialConversationKey: String {
    case conversationId = "conversationId"
}

/// Used to store a conversation that was created by coming in off a Pass or Reservation.
/// Only to be stored locally in shared container that can accessed by the AppClip and the App
final class InitialConveration: PFObject, PFSubclassing {

    static func parseClassName() -> String {
        return String(describing: self)
    }

    var conversationIDString: String? {
        get { return self.getObject(for: .conversationId) }
        set { return self.setObject(for: .conversationId, with: newValue)}
    }

#if IOS
    var cid: ConversationID? {
        guard let conversationIDString = self.conversationIDString else { return nil }
        return try? ConversationID(cid: conversationIDString)
    }
#endif

    func saveLocally() async throws {
        return try await withCheckedThrowingContinuation { continuation in
            self.pinInBackground(withName: "InitialConveration") { success, error in
                if let e = error {
                    continuation.resume(throwing: e)
                } else {
                    continuation.resume(returning: ())
                }
            }
        }
    }

    static func retrieve() async throws -> InitialConveration {
        return try await withCheckedThrowingContinuation({ continuation in
            let query = InitialConveration.query()
            query?.fromPin(withName: "InitialConveration")
            query?.getFirstObjectInBackground(block: { object, error in
                if let initial = object as? InitialConveration {
                    initial.unpinInBackground { result, error in
                        if let e = error {
                            continuation.resume(throwing: e)
                        } else {
                            continuation.resume(returning: initial)
                        }
                    }
                } else if let e = error {
                    continuation.resume(throwing: e)
                } else {
                    continuation.resume(throwing: ClientError.generic)
                }
            })
        })
    }
}

extension InitialConveration: Objectable {
    typealias KeyType = InitialConversationKey

    func getObject<Type>(for key: InitialConversationKey) -> Type? {
        return self.object(forKey: key.rawValue) as? Type
    }

    func setObject<Type>(for key: InitialConversationKey, with newValue: Type) {
        self.setObject(newValue, forKey: key.rawValue)
    }

    func getRelationalObject<PFRelation>(for key: InitialConversationKey) -> PFRelation? {
        return self.relation(forKey: key.rawValue) as? PFRelation
    }
}
