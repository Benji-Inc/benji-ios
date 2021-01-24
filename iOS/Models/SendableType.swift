//
//  SendableType.swift
//  Ours
//
//  Created by Benji Dodgson on 1/23/21.
//  Copyright © 2021 Benjamin Dodgson. All rights reserved.
//

import Foundation

enum SendableType {
    
    case update(ResendableObject)
    case new(SendableObject)

    var kind: MessageKind {
        switch self {
        case .update(let object):
            return object.kind
        case .new(let object):
            return object.kind
        }
    }

    var context: MessageContext {
        switch self {
        case .update(let object):
            return object.context
        case .new(let object):
            return object.context
        }
    }

    var isSendable: Bool {
        switch self {
        case .update(let object):
            return object.kind.isSendable
        case .new(let object):
            return object.kind.isSendable
        }
    }
}

struct SendableObject {
    var kind: MessageKind
    var context: MessageContext
}

struct ResendableObject {
    var previousMessage: Messageable
    var kind: MessageKind
    var context: MessageContext
}
