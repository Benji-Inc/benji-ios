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
    var avatar: PersonType? = nil
    var deliveryStatus: DeliveryStatus = .sent
    var context: MessageContext = .respectful
    var hasBeenConsumedBy: [PersonType] = [SystemAvatar(userObjectId: nil,
                                                    givenName: "system",
                                                    familyName: "avatar",
                                                    image: nil,
                                                    handle: "system")]
    var kind: MessageKind = .text("Some Text")
    var isDeleted: Bool = false
    var totalReplyCount: Int = 0
    var recentReplies: [Messageable] = []
    var lastUpdatedAt: Date? = Date()
    var emotion: Emotion? = .calm

    func setToConsumed() async throws { }
    func setToUnconsumed() async throws { }
}
