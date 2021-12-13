//
//  Notice.swift
//  Jibber
//
//  Created by Benji Dodgson on 5/23/21.
//  Copyright © 2021 Benjamin Dodgson. All rights reserved.
//

import Foundation
import ParseSwift

enum NoticeKey: String {
    case type
    case attributes
    case priority
    case body
}

struct Notice: ParseObject, ParseObjectMutable {
    
    enum NoticeType: String {
        case alert = "ALERT_MESSAGE"
        case connectionRequest = "CONNECTION_REQUEST"
        case connectionConfirmed = "CONNECTION_CONFIRMED"
        case messageRead = "MESSAGE_READ"
        case system
        case rsvps
    }
    
    //: These are required by `ParseObject`.
    var objectId: String?
    var createdAt: Date?
    var updatedAt: Date?
    var ACL: ParseACL?
    
    //    var type: NoticeType? {
    //        get {
    //            guard let value: String = self.getObject(for: .type), let t = NoticeType(rawValue: value) else { return nil }
    //            return t
    //        }
    //    }
    
    //var attributes: [String: AnyHashable]?
    var priority: Int?
    var body: String?
}
