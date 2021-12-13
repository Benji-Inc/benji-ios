//
//  Pass.swift
//  Jibber
//
//  Created by Benji Dodgson on 10/15/21.
//  Copyright © 2021 Benjamin Dodgson. All rights reserved.
//

import Foundation
import ParseSwift

enum PassKey: String {
    case owner
    case attributes
    case connections
    case link
}

struct Pass: ParseObject, ParseObjectMutable {
    
    //: These are required by `ParseObject`.
    var objectId: String?
    var createdAt: Date?
    var updatedAt: Date?
    var ACL: ParseACL?
    
    var owner: User?
    //var attributes: [String: Any]?
    //var connections: ParseRelation<Connection>?
    var link: String?
}

