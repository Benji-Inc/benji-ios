//
//  Conneciton.swift
//  Benji
//
//  Created by Benji Dodgson on 11/2/19.
//  Copyright © 2019 Benjamin Dodgson. All rights reserved.
//

import Foundation
import ParseSwift

enum ConnectionKey: String {
    case status
    case to
    case from
    case conversationSid
    case initialConversations
}

struct Connection: ParseObject, ParseObjectMutable {

    enum Status: String {
        case created 
        case invited
        case pending
        case accepted
        case declined
    }
    
    //: These are required by `ParseObject`.
    var objectId: String?
    var createdAt: Date?
    var updatedAt: Date?
    var ACL: ParseACL?

//    var status: Status? {
//        guard let string: String = self.getObject(for: .status) else { return nil }
//        return Status(rawValue: string)
//    }

    var to: User?
    var from: User?

    var initialConversations: [String] = []

    var nonMeUser: User? {
        if self.to?.objectId == User.current?.objectId {
            return self.from
        } else {
            return self.to
        }
    }
}
