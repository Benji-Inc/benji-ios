//
//  ImageSymbol.swift
//  Jibber
//
//  Created by Benji Dodgson on 5/21/22.
//  Copyright © 2022 Benjamin Dodgson. All rights reserved.
//

import Foundation
import UIKit

enum ImageSymbol: String, ImageDisplayable {
    
    case bellSlash = "bell.slash"
    case bell = "bell"
    case bellFill = "bell.fill"
    case bellBadge = "bell.badge"
    case xMarkCircleFill = "xmark.circle.fill"
    case personCircle = "person.circle"
    case personCropCircle = "person.crop.circle"
    case exclamationmarkTriangle = "exclamationmark.triangle"
    case plus = "plus"
    case trash = "trash"
    case eyeglasses = "eyeglasses"
    case videoFill = "video.fill"
    case faceSmiling = "face.smiling"
    case camera = "camera"
    case mic = "mic"
    case photo = "photo"
    case xMark = "xmark"
    case personBadgePlus = "person.badge.plus"
    case eyeSlash = "eye.slash"
    case handWave = "hand.wave"
    case thumbsUp = "hand.thumbsup"
    case chevronDownCircle = "chevron.down.circle"
    case ellipsis = "ellipsis"
    case arrowTurnUpLeft = "arrowshape.turn.up.left"
    case pencil = "pencil"
    case bookmark = "bookmark"
    case bookmarkSlash = "bookmark.slash"
    case quoteOpening = "quote.opening"
    case personCropCircleBadgePlus = "person.crop.circle.badge.plus"
    case personCropCircleBadgeCheckmark = "person.crop.circle.fill.badge.checkmark"
    case noSign = "nosign"
    case squareAndUp = "square.and.arrow.up"
    case infoCircle = "info.circle"
    case person3 = "person.3"
    case person3Fill = "person.3.fill"
    case rectangleStack = "rectangle.stack"
    case rectangleStackFill = "rectangle.stack.fill"
    case bolt = "bolt"
    case boltFill = "bolt.fill"
    case squareAndPencil = "square.and.pencil"
    case minus = "minus"
    case jibs
    case jiblogo
    
    var image: UIImage? {
        switch self {
        case .jibs:
            return UIImage(named: "jibpurple")
        case .jiblogo:
            return UIImage(named: "jiblogo")
        default:
            return UIImage(systemName: self.rawValue)?.withRenderingMode(.alwaysTemplate)
        }
    }
        
    var defaultConfig: UIImage.SymbolConfiguration? {
        var colors: [ThemeColor] = []
        
        switch self {
        case .bellSlash, .personCircle:
            colors = [.whiteWithAlpha, .white]
        case .bell, .bellFill, .person3, .person3Fill, .bolt, .boltFill, .rectangleStack, .rectangleStackFill:
            colors = [.white]
        case .bellBadge:
            colors = [.red, .white]
        case .xMarkCircleFill:
            colors = [.whiteWithAlpha, .whiteWithAlpha]
        default:
            return nil 
        }
        
        let uicolors = colors.compactMap { color in
            return color.color
        }
        let config = UIImage.SymbolConfiguration.init(paletteColors: uicolors)
        let multi = UIImage.SymbolConfiguration.preferringMulticolor()
        let combined = config.applying(multi)
        return combined
    }
    
    var highlightSymbol: ImageSymbol? {
        return nil 
    }
    
    var selectedSymbol: ImageSymbol? {
        switch self {
        case .bolt:
            return .xMark
        default:
            return nil
        }
    }
}
