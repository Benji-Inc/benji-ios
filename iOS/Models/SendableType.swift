//
//  SendableType.swift
//  Ours
//
//  Created by Benji Dodgson on 1/23/21.
//  Copyright © 2021 Benjamin Dodgson. All rights reserved.
//

import Foundation

protocol Sendable: AnyObject {
    var kind: MessageKind { get set }
    var context: MessageContext { get set }
    var previousMessage: Messageable? { get set }
    var isSendable: Bool { get }
}

class SendableObject: Sendable {

    var kind: MessageKind
    var context: MessageContext
    var previousMessage: Messageable?

    var isSendable: Bool {
        return self.kind.isSendable
    }

    init(kind: MessageKind,
         context: MessageContext,
         previousMessage: Messageable? = nil) {

        self.kind = kind
        self.context = context
        self.previousMessage = previousMessage
    }
}
