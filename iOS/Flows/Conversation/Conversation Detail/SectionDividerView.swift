//
//  SectionDividerView.swift
//  Jibber
//
//  Created by Benji Dodgson on 4/2/22.
//  Copyright © 2022 Benjamin Dodgson. All rights reserved.
//

import Foundation

class SectionDividerView: UICollectionReusableView {
    
    let leftLabel = ThemeLabel(font: .regular)
    let imageView = SymbolImageView(symbol: .plus)
    let button = ThemeButton()
    
    var didSelectButton: CompletionOptional = nil
        
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.initializeViews()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        self.initializeViews()
    }
    
    func initializeViews() {
        
        self.addSubview(self.leftLabel)
        self.leftLabel.textAlignment = .left

        
        self.addSubview(self.button)
        self.button.didSelect { [unowned self] in
            self.didSelectButton?()
        }
        
        self.addSubview(self.imageView)
        self.imageView.tintColor = ThemeColor.white.color
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        self.leftLabel.setSize(withWidth: self.width)
        self.leftLabel.centerOnY()
        self.leftLabel.pin(.left, offset: .standard)
        
        self.imageView.squaredSize = 20
        self.imageView.centerOnY()
        self.imageView.pin(.right, offset: .standard)
        
        self.button.squaredSize = self.height
        self.button.center = self.imageView.center
    }
}
