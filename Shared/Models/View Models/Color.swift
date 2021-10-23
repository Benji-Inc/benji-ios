//
//  Color.swift
//  Benji
//
//  Created by Benji Dodgson on 12/25/18.
//  Copyright © 2018 Benjamin Dodgson. All rights reserved.
//

import Foundation
import UIKit

enum Color: String, CaseIterable {

    case background
    case darkGray
    case gray
    case lightGray
    case textColor
    case white
    case clear

    var color: UIColor {
        switch self {
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
        }
    }
}
