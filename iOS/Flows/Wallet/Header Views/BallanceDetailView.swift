//
//  BallanceDetailView.swift
//  Jibber
//
//  Created by Benji Dodgson on 2/15/22.
//  Copyright © 2022 Benjamin Dodgson. All rights reserved.
//

import Foundation
import ScrollCounter

class BallanceDetailView: BaseView {
    
    let titleLabel = NumberScrollCounter(value: 0.0,
                                         scrollDuration: Theme.animationDurationSlow,
                                         decimalPlaces: 2,
                                         prefix: "$",
                                         suffix: nil,
                                         seperator: ".",
                                         seperatorSpacing: 0,
                                         font: FontType.medium.font,
                                         textColor: ThemeColor.T1.color,
                                         animateInitialValue: true,
                                         gradientColor: ThemeColor.B0.color,
                                         gradientStop: 4)
    
    let subtitleLabel = ThemeLabel(font: .small, textColor: .D1)
    private let showDetail: Bool
    private let detailDisclosure = UIImageView(image: UIImage(systemName: "info.circle"))
    
    init(showDetail: Bool = false) {
        self.showDetail = showDetail
        super.init()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func initializeSubviews() {
        super.initializeSubviews()
        
        self.addSubview(self.detailDisclosure)
        self.tintColor = ThemeColor.T1.color
        self.detailDisclosure.isHidden = !self.showDetail
        self.addSubview(self.titleLabel)
        self.addSubview(self.subtitleLabel)
        self.subtitleLabel.textAlignment = .right
    }
        
    func configure(with value: Double) {
        self.titleLabel.setValue(Float(floor(value * 100) / 100), animated: true)
        self.layoutNow()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        self.titleLabel.sizeToFit()
        self.subtitleLabel.setSize(withWidth: 200)
        
        self.height = self.titleLabel.height + Theme.ContentOffset.short.value + self.subtitleLabel.height
        if self.showDetail {
            self.width = self.titleLabel.width + Theme.ContentOffset.short.value + 18
        } else {
            self.width = self.titleLabel.width > self.subtitleLabel.width ? self.titleLabel.width : self.subtitleLabel.width
        }
        
        self.titleLabel.pin(.right)
        self.subtitleLabel.pin(.right)
        
        self.titleLabel.pin(.top)
        self.subtitleLabel.pin(.bottom)
        
        self.detailDisclosure.squaredSize = 18
        self.detailDisclosure.centerY = self.titleLabel.centerY
        self.detailDisclosure.match(.right, to: .left, of: self.titleLabel, offset: .negative(.short))
    }
}
