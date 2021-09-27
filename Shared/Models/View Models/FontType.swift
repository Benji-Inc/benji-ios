//
//  Font.swift
//  Benji
//
//  Created by Benji Dodgson on 12/27/18.
//  Copyright © 2018 Benjamin Dodgson. All rights reserved.
//

import Foundation
import UIKit

enum FontType {

    case display
    case displayUnderlined
    case displayThin
    case largeThin
    case medium
    case mediumThin
    case mediumBold
    case regular
    case regularBold
    case small
    case smallBold

    var font: UIFont {
        switch self {
        case .display, .displayUnderlined:
            return UIFont.systemFont(ofSize: self.size, weight: .heavy)
        case .displayThin, .mediumThin, .largeThin:
            return UIFont.systemFont(ofSize: self.size, weight: .ultraLight)
        case .medium, .regular, .small:
            return UIFont.systemFont(ofSize: self.size, weight: .regular)
        case .mediumBold, .regularBold, .smallBold:
            return UIFont.systemFont(ofSize: self.size, weight: .bold)
        }
    }

    var size: CGFloat {
        switch self {
        case .displayThin:
            return 60
        case .display:
            return 40
        case .displayUnderlined:
            return 32
        case .largeThin:
            return 30
        case .medium, .mediumBold, .mediumThin:
            return 24
        case .regular, .regularBold:
            return 20
        case .small, .smallBold:
            return 14
        }
    }

    var kern: CGFloat {
        switch self {
        case .displayThin:
            return 0
        default:
            return 1
        }
    }

    var underlineStyle: NSUnderlineStyle {
        switch self {
        case .displayUnderlined:
            return .single
        default:
            return []
        }
    }
}
