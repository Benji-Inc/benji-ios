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
    case foo
    
    func getImage(for font: FontType) -> UIImage? {
        return UIImage(systemName: self.rawValue, withConfiguration: font.symbolConfiguration)
    }
}
