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
    
    case B1
    case B2
    case D1
    case D6
    case L1

    case border
    case background
    case darkGray
    case gray
    case lightGray
    case textColor
    case white
    case clear
    case red

    var color: UIColor {
        switch self {
        case .border:
            return UIColor(named: "BORDER")!
        case .background:
            return UIColor(named: "BACKGROUND")!
        case .darkGray:
            return UIColor(named: "DARKGRAY")!
        case .gray:
            return UIColor(named: "GRAY")!
        case .lightGray:
            return UIColor(named: "LIGHTGRAY")!
        case .textColor:
            return UIColor(named: "TEXTCOLOR")!
        case .white:
            return UIColor(named: "WHITE")!
        case .clear:
            return UIColor(named: "CLEAR")!
        case .red:
            return UIColor(named: "RED")!
            
        case .B1:
            return UIColor(named: "B1")!
        case .B2:
            return UIColor(named: "B2")!
        case .D1:
            return UIColor(named: "D1")!
        case .D6:
            return UIColor(named: "D6")!
        case .L1:
            return UIColor(named: "L1")!
        }
    }
    
    var ciColor: CIColor {
        return CIColor(color: self.color)
    }
}
