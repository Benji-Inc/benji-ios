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
    var expressionURL: URL? { get set }
    var previousMessage: Messageable? { get set }
    var isSendable: Bool { get }
}

class SendableObject: Sendable {

    var kind: MessageKind
    var deliveryType: MessageDeliveryType
    var previousMessage: Messageable?
    var expression: Emoji?
    var expressionURL: URL?

    var isSendable: Bool {
        return self.kind.isSendable || self.expressionURL.exists
    }

    init(kind: MessageKind,
         deliveryType: MessageDeliveryType,
         expression: Emoji?,
         expressionURL: URL?,
         previousMessage: Messageable? = nil) {

        self.kind = kind
        self.deliveryType = deliveryType
        self.expression = expression
        self.expressionURL = expressionURL
        self.previousMessage = previousMessage
    }
}
