//
//  CountingHeaderDetailView.swift
//  Jibber
//
//  Created by Benji Dodgson on 2/15/22.
//  Copyright © 2022 Benjamin Dodgson. All rights reserved.
//

import Foundation
import ScrollCounter

class JibsDetailView: BaseView {
    
    let titleLabel = NumberScrollCounter(value: 0.0,
                                         scrollDuration: Theme.animationDurationSlow,
                                         decimalPlaces: 6,
                                         prefix: nil,
                                         suffix: nil,
                                         seperator: ".",
                                         seperatorSpacing: 0,
                                         font: FontType.medium.font,
                                         textColor: ThemeColor.white.color,
                                         animateInitialValue: true,
                                         gradientColor: ThemeColor.B0.color,
                                         gradientStop: 4)
    
    let subtitleLabel = ThemeLabel(font: .small)
    
    override func initializeSubviews() {
        super.initializeSubviews()
        
        self.addSubview(self.titleLabel)
        self.addSubview(self.subtitleLabel)
        self.subtitleLabel.alpha = 0.25
        self.subtitleLabel.textAlignment = .right
    }
        
    func configure(with value: Double) {
        self.titleLabel.setValue(Float(value), animated: true)
        self.layoutNow()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        self.titleLabel.sizeToFit()
        self.subtitleLabel.setSize(withWidth: 200)
        
        self.height = self.titleLabel.height + Theme.ContentOffset.short.value + self.subtitleLabel.height
        self.width = self.titleLabel.width > self.subtitleLabel.width ? self.titleLabel.width : self.subtitleLabel.width
        
        self.titleLabel.pin(.right)
        self.subtitleLabel.pin(.right)
        
        self.titleLabel.pin(.top)
        self.subtitleLabel.pin(.bottom)
    }
}
