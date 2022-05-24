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
    
    var image: UIImage {
        return UIImage(systemName: self.rawValue)!.withRenderingMode(.alwaysTemplate)
    }
}
