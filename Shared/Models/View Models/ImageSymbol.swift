//
//  ImageSymbol.swift
//  Jibber
//
//  Created by Benji Dodgson on 5/21/22.
//  Copyright © 2022 Benjamin Dodgson. All rights reserved.
//

import Foundation
import UIKit

enum ImageSymbol: String {
    
    case bellSlash = "bell.slash"
    case bell = "bell"
    case bellBadge = "bell.badge"
    case xMarkCircleFill = "xmark.circle.fill"
    
    var image: UIImage {
        return UIImage(systemName: self.rawValue)!.withRenderingMode(.alwaysTemplate)
    }
        
    var defaultConfig: UIImage.SymbolConfiguration? {
        var colors: [ThemeColor] = []
        
        switch self {
        case .bellSlash:
            colors = [.whiteWithAlpha, .white]
        case .bell:
            colors = [.white]
        case .bellBadge:
            colors = [.red, .white]
        case .xMarkCircleFill:
            colors = [.whiteWithAlpha, .whiteWithAlpha]
        }
        
        let uicolors = colors.compactMap { color in
            return color.color
        }
        let config = UIImage.SymbolConfiguration.init(paletteColors: uicolors)
        let multi = UIImage.SymbolConfiguration.preferringMulticolor()
        let combined = config.applying(multi)
        return combined
    }
}
