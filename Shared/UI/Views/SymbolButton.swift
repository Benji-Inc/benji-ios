//
//  ThemeImageViewButton.swift
//  Jibber
//
//  Created by Benji Dodgson on 5/26/22.
//  Copyright © 2022 Benjamin Dodgson. All rights reserved.
//

import Foundation
import UIKit

class SymbolButton: UIButton {
    
    var poinSize: CGFloat?
    private lazy var symbolImageView = SymbolImageView(symbol: self.symbol)
    private var symbol: ImageSymbol?
    
    init(symbol: ImageSymbol? = nil) {
        self.symbol = symbol
        super.init(frame: .zero)
        self.addSubview(self.symbolImageView)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.addSubview(self.symbolImageView)
    }
    
    func set(symbol: ImageSymbol, pointSize: CGFloat?) {
        self.poinSize = pointSize
        self.symbolImageView.set(symbol: symbol)
        self.setNeedsLayout()
    }
    
    func set(config: UIImage.SymbolConfiguration) {
        self.symbolImageView.preferredSymbolConfiguration = config
        self.setNeedsLayout()
    }
    
    func set(tintColor: ThemeColor) {
        self.symbolImageView.tintColor = tintColor.color
        self.setNeedsLayout()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        if let pointSize = self.poinSize {
            self.symbolImageView.squaredSize = pointSize
            self.symbolImageView.centerOnXAndY()
        } else {
            self.symbolImageView.expandToSuperviewSize()
        }
    }
}
