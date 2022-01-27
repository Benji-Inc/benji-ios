//
//  CircleItem.swift
//  Jibber
//
//  Created by Benji Dodgson on 1/27/22.
//  Copyright © 2022 Benjamin Dodgson. All rights reserved.
//

import Foundation
import Contacts

struct CircleItem: Hashable {
    var position: Int 
    var user: User?
    var contact: CNContact? 
}
