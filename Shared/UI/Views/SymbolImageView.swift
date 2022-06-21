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
    
    init(symbol: ImageSymbol? = nil) {
        self.symbol = symbol
        super.init(image: symbol?.image, highlightedImage: symbol?.highlightSymbol?.image)
        self.contentMode = .scaleAspectFit
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    func set(symbol: ImageSymbol, configuration: UIImage.SymbolConfiguration? = nil) {

        self.symbol = symbol
        self.image = self.symbol?.image
        self.highlightedImage = self.symbol?.highlightSymbol?.image
        if let config = configuration {
            self.preferredSymbolConfiguration = config
        } else if let config = symbol.defaultConfig {
            self.preferredSymbolConfiguration = config
        }
    }
}
