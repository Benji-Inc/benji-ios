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
    case medium
    case mediumBold
    case regular
    case regularBold
    case small
    case smallBold
    case xtraSmall
    case contextCues
    
    var symbolConfiguration: UIImage.SymbolConfiguration {
        return UIImage.SymbolConfiguration(font: self.font)
    }

    var font: UIFont {
        switch self {
        case .display, .medium, .regular, .small, .xtraSmall, .contextCues:
            return UIFont.systemFont(ofSize: self.size)
        case .mediumBold, .regularBold, .smallBold:
            return UIFont.systemFont(ofSize: self.size, weight: .bold)
        }
    }

    var size: CGFloat {
        switch self {
        case .display:
            return 36
        case .contextCues:
            return 26
        case .medium, .mediumBold:
            return 20
        case .regular, .regularBold:
            return 16
        case .small, .smallBold:
            return 12
        case .xtraSmall:
            return 8
        }
    }

    var kern: CGFloat {
        switch self {
        case .small, .xtraSmall:
            return 0
        case .contextCues:
            return 2
        default:
            return 0.2
        }
    }

    var underlineStyle: NSUnderlineStyle {
        return []
    }
}
