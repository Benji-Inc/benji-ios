//
//  MockMessage.swift
//  Jibber
//
//  Created by Martin Young on 2/8/22.
//  Copyright © 2022 Benjamin Dodgson. All rights reserved.
//

import Foundation

struct MockMessage: Messageable {

    var id: String = UUID().uuidString
    var conversationId: String = UUID().uuidString
    var createdAt: Date = Date()
    var isFromCurrentUser: Bool = true
    var authorId: String = UUID().uuidString
    var attributes: [String : Any]? = nil
    var person: PersonType? = nil
    var deliveryStatus: DeliveryStatus = .sent
    var deliveryType: MessageDeliveryType = .respectful
    var hasBeenConsumedBy: [PersonType] = [SystemAvatar(givenName: "system",
                                                        familyName: "person",
                                                        handle: "system",
                                                        image: nil)]
    var kind: MessageKind = .text("Some Text")
    var isDeleted: Bool = false
    var totalReplyCount: Int = 0
    var recentReplies: [Messageable] = []
    var lastUpdatedAt: Date? = Date()
    var expressions: [ExpressionInfo] = []
    
    func setToConsumed() async { }
    func setToUnconsumed() async throws { }
}
