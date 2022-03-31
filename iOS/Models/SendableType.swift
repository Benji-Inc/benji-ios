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
    var deliveryType: MessageDeliveryType { get set }
    var expression: Emoji? { get set }
    var previousMessage: Messageable? { get set }
    var isSendable: Bool { get }
}

class SendableObject: Sendable {

    var kind: MessageKind
    var deliveryType: MessageDeliveryType
    var previousMessage: Messageable?
    var expression: Emoji?

    var isSendable: Bool {
        return self.kind.isSendable
    }

    init(kind: MessageKind,
         deliveryType: MessageDeliveryType,
         expression: Emoji?,
         previousMessage: Messageable? = nil) {

        self.kind = kind
        self.deliveryType = deliveryType
        self.expression = expression
        self.previousMessage = previousMessage
    }
}
