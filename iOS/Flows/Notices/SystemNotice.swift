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
    var attributes: [String: AnyHashable]? { get set }
}

struct SystemNotice: Noticeable, Comparable {

    var notice: Notice?
    var created: Date?
    var attributes: [String : AnyHashable]?

    init(createdAt: Date?,
         notice: Notice?,
         attributes: [String: AnyHashable]?) {

        self.created = createdAt
        self.notice = notice
        self.attributes = attributes
    }

    init(with notice: Notice) {

        self.init(createdAt: notice.createdAt,
                  notice: notice,
                  attributes: notice.attributes)
    }

    static func == (lhs: SystemNotice, rhs: SystemNotice) -> Bool {
        return lhs.notice == rhs.notice &&
            lhs.created == rhs.created
    }

    static func < (lhs: SystemNotice, rhs: SystemNotice) -> Bool {
        return lhs.created! < rhs.created!
    }
}
