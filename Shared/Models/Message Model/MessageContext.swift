//
//  MessageContext.swift
//  Benji
//
//  Created by Benji Dodgson on 6/29/19.
//  Copyright © 2019 Benjamin Dodgson. All rights reserved.
//

import Foundation
import TMROLocalization

enum MessageContext: String, CaseIterable {

    case timeSensitive
    case passive
    case status

    var color: Color {
        switch self {
        case .timeSensitive:
            return .red
        case .passive:
            return .textColor
        case .status:
            return .textColor
        }
    }
}
