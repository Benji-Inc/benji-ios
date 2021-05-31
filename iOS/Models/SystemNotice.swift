//
//  SystemNotice.swift
//  Ours
//
//  Created by Benji Dodgson on 5/31/21.
//  Copyright © 2021 Benjamin Dodgson. All rights reserved.
//

import Foundation

protocol Noticeable: Hashable {
    var notice: Notice? { get set }
    var created: Date? { get set }
    var priority: Int? { get set }
    var attributes: [String: AnyHashable]? { get set }
}

struct SystemNotice: Noticeable, Comparable {

    var notice: Notice?
    var type: Notice.NoticeType?
    var body: String?
    var created: Date?
    var priority: Int?
    var attributes: [String : AnyHashable]?

    init(createdAt: Date?,
         notice: Notice?,
         type: Notice.NoticeType,
         priority: Int?,
         body: String?,
         attributes: [String: AnyHashable]?) {

        self.created = createdAt
        self.notice = notice
        self.attributes = attributes
        self.priority = priority
        self.type = type
        self.body = body
    }

    init(with notice: Notice) {

        self.init(createdAt: notice.createdAt,
                  notice: notice,
                  type: notice.type!,
                  priority: notice.priority!,
                  body: notice.body,
                  attributes: notice.attributes)
    }

    static func == (lhs: SystemNotice, rhs: SystemNotice) -> Bool {
        return lhs.notice == rhs.notice &&
            lhs.type == rhs.type &&
            lhs.priority == rhs.priority &&
            lhs.body == rhs.body &&
            lhs.created == rhs.created
    }

    static func < (lhs: SystemNotice, rhs: SystemNotice) -> Bool {
        return lhs.priority! < rhs.priority!
    }
}
