//
//  Font.swift
//  Benji
//
//  Created by Benji Dodgson on 12/27/18.
//  Copyright © 2018 Benjamin Dodgson. All rights reserved.
//

import Foundation
import UIKit

private let boldFontName = "SFProText-Bold"
private let regularFontName = "SFProText-Regular"

enum FontType {

    case display
    case medium
    case mediumBold
    case regular
    case regularBold
    case small
    case smallBold
    case xtraSmall
    case reactionEmoji
    case system
    case systemLarge
    case systemSmall
    case systemBold
    case contextCues

    var font: UIFont {
    #if APPCLIP
        return UIFont.systemFont(ofSize: self.size)
    #else
        switch self {
        case .system, .systemLarge, .systemSmall, .contextCues:
            return UIFont.systemFont(ofSize: self.size)
        case .systemBold:
            return UIFont.systemFont(ofSize: self.size, weight: .bold)
        case .display, .medium, .regular, .small, .xtraSmall:
            return UIFont(name: regularFontName, size: self.size)!
        case .mediumBold, .regularBold, .smallBold:
            return UIFont(name: boldFontName, size: self.size)!
        case .reactionEmoji:
            return UIFont.systemFont(ofSize: self.size)
        }
    #endif
    }

    var size: CGFloat {
        switch self {
        case .display, .systemLarge:
            return 30
        case .contextCues:
            return 26
        case .medium, .mediumBold:
            return 20
        case .regular, .regularBold:
            return 16
        case .small, .smallBold, .reactionEmoji, .systemSmall:
            return 12
        case .xtraSmall:
            return 8
        case .system, .systemBold:
            return 16
        }
    }

    var kern: CGFloat {
        switch self {
        case .small, .xtraSmall, .system, .systemBold:
            return 0
        case .contextCues:
            return 2
        default:
            return -0.5
        }
    }

    var underlineStyle: NSUnderlineStyle {
        return []
    }
}
