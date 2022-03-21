//
//  ThemeColor.swift
//  Benji
//
//  Created by Benji Dodgson on 12/25/18.
//  Copyright © 2018 Benjamin Dodgson. All rights reserved.
//

import Foundation
import UIKit

enum ThemeColor: String, CaseIterable {
    
    case B0
    case B1
    case B1withAlpha
    case B2
    case B3
    case B4
    case B5
    case B6
    case D1
    case D4BottomRight
    case D4TopLeft
    case D6
    case BORDER
    case L1
    case L4TopLeft
    case L4BottomRight
    case T1
    case T1withAlpha
    case T2
    case T3
    case T4
    
    case badgeTop
    case badgeBottom
    case badgeHighlightTop
    case badgeHighlightBottom
    case walletBackground
    
    case white
    case clear
    case red
    case gray
    case yellow

    var color: UIColor {
        switch self {
            
        case .gray:
            return UIColor(named: "GRAY")!
        case .white:
            return UIColor(named: "WHITE")!
        case .clear:
            return UIColor(named: "CLEAR")!
        case .red:
            return UIColor(named: "RED")!
        case .yellow:
            return UIColor(named: "YELLOW")!
        case .B1withAlpha:
            return ThemeColor.B1.color.withAlphaComponent(0.3)
        case .B1:
            return UIColor(named: "B1")!
        case .B2:
            return UIColor(named: "B2")!
        case .B3:
            return UIColor(named: "B3")!
        case .B4:
            return UIColor(named: "B4")!
        case .B5:
            return UIColor(named: "B5")!
        case .B6:
            return UIColor(named: "B6")!
        case .D1:
            return UIColor(named: "D1")!
        case .D4TopLeft:
            return UIColor(named: "D4_TOP_LEFT")!
        case .D4BottomRight:
            return UIColor(named: "D4_BOTTOM_RIGHT")!
        case .D6:
            return UIColor(named: "D6")!
        case .BORDER:
            return UIColor(named: "BORDER")!
        case .L1:
            return UIColor(named: "L1")!
        case .L4TopLeft:
            return UIColor(named: "L4_TOP_LEFT")!
        case .L4BottomRight:
            return UIColor(named: "L4_BOTTOM_RIGHT")!
        case .T1:
            return UIColor(named: "T1")!
        case .T1withAlpha:
            return ThemeColor.T1.color.withAlphaComponent(0.5)
        case .T2:
            return UIColor(named: "T2")!
        case .T3:
            return UIColor(named: "T3")!
        case .T4:
            return UIColor(named: "T4")!
        case .B0:
            return UIColor(named: "B0")!
            
        case .badgeTop:
            return UIColor(named: "BADGE_TOP")!
        case .badgeBottom:
            return UIColor(named: "BADGE_BOTTOM")!
            
        case .badgeHighlightTop:
            return UIColor(named: "BADGE_HIGHLIGHT_TOP")!
        case .badgeHighlightBottom:
            return UIColor(named: "BADGE_HIGHLIGHT_BOTTOM")!
            
        case .walletBackground:
            return UIColor(named: "WALLET_BACKGROUND")!
        }
    }
    
    var ciColor: CIColor {
        return CIColor(color: self.color)
    }
}
