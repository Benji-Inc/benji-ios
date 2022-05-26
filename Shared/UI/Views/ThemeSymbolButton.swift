//
//  ThemeImageViewButton.swift
//  Jibber
//
//  Created by Benji Dodgson on 5/26/22.
//  Copyright © 2022 Benjamin Dodgson. All rights reserved.
//

import Foundation
import UIKit

class ThemeSymbolButton: BaseView {
    
    var poinSize: CGFloat?
    var symbol: ImageSymbol?
    private let imageView = UIImageView()
    
    override func initializeSubviews() {
        super.initializeSubviews()
        
        self.addSubview(self.imageView)
        self.imageView.contentMode = .scaleAspectFit
    }
    
    func set(symbol: ImageSymbol, pointSize: CGFloat?) {
        self.symbol = symbol
        self.poinSize = pointSize
        self.imageView.image = self.symbol?.image
        if let config = symbol.defaultConfig {
            self.imageView.preferredSymbolConfiguration = config
        }
        
        self.setNeedsLayout()
    }
    
    func set(config: UIImage.SymbolConfiguration) {
        self.imageView.preferredSymbolConfiguration = config
        self.setNeedsLayout()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        if let pointSize = self.poinSize {
            self.imageView.squaredSize = pointSize
            self.imageView.centerOnXAndY()
        } else {
            self.imageView.expandToSuperviewSize()
        }
    }
}
