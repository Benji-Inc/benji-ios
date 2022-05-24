//
//  MessageDeliveryType.swift
//  Benji
//
//  Created by Benji Dodgson on 6/29/19.
//  Copyright © 2019 Benjamin Dodgson. All rights reserved.
//

import Foundation
import UIKit

enum MessageDeliveryType: String, CaseIterable {

    case timeSensitive = "time-sensitive"
    case conversational = "conversational"
    case respectful = "respectful"

    var color: ThemeColor {
        return .B1
    }

    var displayName: String {
        switch self {
        case .timeSensitive:
            return "Time Sensitive"
        case .conversational:
            return "Conversational"
        case .respectful:
            return "Small Talk"
        }
    }
    
    var description: String {
        switch self {
        case .timeSensitive:
            return "Notify no matter what"
        case .conversational:
            return "Notify if available"
        case .respectful:
            return "No need to notify"
        }
    }
    
    var image: UIImage? {
        switch self {
        case .timeSensitive:
            return ImageSymbol.bellBadge.image
        case .conversational:
            return ImageSymbol.bell.image
        case .respectful:
            return ImageSymbol.bellSlash.image
        }
    }
    
    func getConfiguration() -> UIImage.SymbolConfiguration {
        let colors: [ThemeColor]
        
        switch self {
        case .timeSensitive:
            colors = [.red, .white]
        case .conversational:
            colors = [.white]
        case .respectful:
            colors = [.whiteWithAlpha, .white]
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
