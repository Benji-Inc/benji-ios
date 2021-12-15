//
//  Deeplinkable.swift
//  Benji
//
//  Created by Benji Dodgson on 6/22/19.
//  Copyright © 2019 Benjamin Dodgson. All rights reserved.
//

import Foundation
import StreamChat

protocol DeepLinkable {
    var customMetadata: NSMutableDictionary { get set }
    var deepLinkTarget: DeepLinkTarget? { get set }
    var reservationId: String? { get set }
    var reservationCreatorId: String? { get set }
    var passId: String? { get set }
}

extension DeepLinkable {
    subscript(key: String) -> Any? {
        get {
            return self.customMetadata[key]
        }

        set (newValue) {
            self.customMetadata[key] = newValue
        }
    }
}

extension DeepLinkable {

#if IOS
    var conversationId: ConversationID? {
        get {
            guard let stringCID = self.customMetadata.value(forKey: "conversationId") as? String else {
                return nil
            }
            return try? ConversationID(cid: stringCID)
        }
        set {
            let stringCID = newValue?.description
            self.customMetadata.setValue(stringCID, forKey: "conversationId")
        }
    }

    var messageId: MessageId? {
        get {
            return self.customMetadata.value(forKey: "messageId") as? String
        }
        set {
            self.customMetadata.setValue(newValue, forKey: "messageId")
        }
    }
#endif

    var reservationId: String? {
        get {
            return self.customMetadata.value(forKey: "reservationId") as? String
        }
        set {
            self.customMetadata.setValue(newValue, forKey: "reservationId")
        }
    }

    var reservationCreatorId: String? {
        get {
            return self.customMetadata.value(forKey: ReservationKey.createdBy.rawValue) as? String
        }
        set {
            self.customMetadata.setValue(newValue, forKey: ReservationKey.createdBy.rawValue)
        }
    }

    var passId: String? {
        get {
            return self.customMetadata.value(forKey: "passId") as? String
        }
        set {
            self.customMetadata.setValue(newValue, forKey: "passId")
        }
    }
}
