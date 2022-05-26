//
//  AddView.swift
//  Jibber
//
//  Created by Benji Dodgson on 1/15/22.
//  Copyright © 2022 Benjamin Dodgson. All rights reserved.
//

import Foundation

class AddView: BaseView {
    
    let imageView = SymbolImageView()
        
    override func initializeSubviews() {
        super.initializeSubviews()
        
        self.set(backgroundColor: .B6)
        self.addSubview(self.imageView)
        self.imageView.set(symbol: .plus)
        self.imageView.tintColor = UIColor.white.withAlphaComponent(0.8)
        
        self.layer.borderColor = ThemeColor.white.color.withAlphaComponent(0.3).cgColor
        self.layer.borderWidth = 1
        self.layer.masksToBounds = true
        self.layer.cornerRadius = Theme.innerCornerRadius
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        self.imageView.squaredSize = self.height * 0.5
        self.imageView.centerOnXAndY()
    }
}
