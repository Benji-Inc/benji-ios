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
    var avatar: Avatar? = nil
    var status: MessageStatus = .delivered
    var context: MessageContext = .respectful
    var hasBeenConsumedBy: [Avatar] = []
    var kind: MessageKind = .text("Some Text")
    var isDeleted: Bool = false
    var totalReplyCount: Int = 0
    var recentReplies: [Messageable] = []
    var lastUpdatedAt: Date? = Date()
    var emotion: Emotion? = .calm

    func setToConsumed() async throws { }
    func setToUnconsumed() async throws { }
}
