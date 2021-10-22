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
    case lightGray
    case textColor
    case white
    case clear

    var color: UIColor {
        switch self {
        case .background:
            return UIColor(named: "Background1")!
        case .darkGray:
            return UIColor(named: "Background2")!
        case .lightGray:
            return UIColor(named: "Background3")!
        case .textColor:
            return UIColor(named: "Background4")!
        case .white:
            return UIColor(named: "White")!
        case .clear:
            return UIColor(named: "Clear")!
        }
    }
}
