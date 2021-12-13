//
//  QuePositions.swift
//  Jibber
//
//  Created by Benji Dodgson on 1/5/21.
//  Copyright © 2021 Benjamin Dodgson. All rights reserved.
//

import Foundation
import ParseSwift

enum QuePositionsKey: String {
    case max = "maxQuePostions"
    case unclaimed = "unclaimedPostion"
    case claimed = "claimedPosition"
}

struct QuePositions: ParseObject, ParseObjectMutable {

    //: These are required by `ParseObject`.
    var objectId: String?
    var createdAt: Date?
    var updatedAt: Date?
    var ACL: ParseACL?

    var max: Int?
    var unclaimed: Int?
    var claimed: Int?
}
