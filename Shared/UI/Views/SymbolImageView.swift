//
//  SymbolImageView.swift
//  Jibber
//
//  Created by Benji Dodgson on 5/26/22.
//  Copyright © 2022 Benjamin Dodgson. All rights reserved.
//

import Foundation
import UIKit

class SymbolImageView: UIImageView {
    
    var symbol: ImageSymbol?
    
    func set(symbol: ImageSymbol) {
        self.contentMode = .scaleAspectFit

        self.symbol = symbol
        self.image = self.symbol?.image
        if let config = symbol.defaultConfig {
            self.preferredSymbolConfiguration = config
        }
    }
}
