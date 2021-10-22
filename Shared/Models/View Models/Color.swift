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

    case background1
    case background2
    case background3
    case background4
    case purple
    case lightPurple
    case white
    case clear

    var color: UIColor {
        switch self {
        case .background1:
            return UIColor(named: "Background1")!
        case .background2:
            return UIColor(named: "Background2")!
        case .background3:
            return UIColor(named: "Background3")!
        case .background4:
            return UIColor(named: "Background4")!
        case .purple:
            return UIColor(named: "Purple")!
        case .lightPurple:
            return UIColor(named: "LightPurple")!
        case .white:
            return UIColor(named: "White")!
        case .clear:
            return UIColor(named: "Clear")!
        }
    }
}
