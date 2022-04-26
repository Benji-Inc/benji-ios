//
//  Toast.swift
//  Jibber
//
//  Created by Benji Dodgson on 5/3/21.
//  Copyright © 2021 Benjamin Dodgson. All rights reserved.
//

import Foundation
import Localization

struct Toast: Equatable {

    enum DisplayType {
        case banner
        case status
    }

    enum Position {
        case top
        case bottom
    }

    var id: String
    var priority: Int = 0
    var title: Localized
    var description: Localized
    var displayable: ImageDisplayable
    var deeplink: DeepLinkable?
    var type: DisplayType
    var position: Position
    var duration: TimeInterval
    var didTap: () -> Void

    static func == (lhs: Toast, rhs: Toast) -> Bool {
        return lhs.id == rhs.id
    }
}
