//
//  SendableType.swift
//  Jibber
//
//  Created by Benji Dodgson on 1/23/21.
//  Copyright © 2021 Benjamin Dodgson. All rights reserved.
//

import Foundation
import Intents

protocol Sendable: AnyObject {
    var kind: MessageKind { get set }
    var context: MessageDeliveryType { get set }
    var expression: Emoji? { get set }
    var previousMessage: Messageable? { get set }
    var isSendable: Bool { get }
}

class SendableObject: Sendable {

    var kind: MessageKind
    var context: MessageDeliveryType
    var previousMessage: Messageable?
    var expression: Emoji?

    var isSendable: Bool {
        return self.kind.isSendable
    }

    init(kind: MessageKind,
         context: MessageDeliveryType,
         expression: Emoji?,
         previousMessage: Messageable? = nil) {

        self.kind = kind
        self.context = context
        self.expression = expression
        self.previousMessage = previousMessage
    }
}
