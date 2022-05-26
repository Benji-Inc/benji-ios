//
//  WalletHeaderDetailView.swift
//  Jibber
//
//  Created by Benji Dodgson on 2/15/22.
//  Copyright © 2022 Benjamin Dodgson. All rights reserved.
//

import Foundation

class WalletHeaderDetailView: BaseView {
    
    let titleLabel = ThemeLabel(font: .medium)
    let subtitleLabel = ThemeLabel(font: .small, textColor: .D1)

    private let shouldPinLeft: Bool
    private let detailDisclosure = SymbolImageView(symbol: .infoCircle)
    private let showDetail: Bool

    init(shouldPinLeft: Bool, showDetail: Bool) {
        self.showDetail = showDetail
        self.shouldPinLeft = shouldPinLeft
        super.init()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func initializeSubviews() {
        super.initializeSubviews()
        
        self.addSubview(self.detailDisclosure)
        self.detailDisclosure.tintColor = ThemeColor.white.color.resolvedColor(with: self.traitCollection)
        self.detailDisclosure.isHidden = !self.showDetail
        
        self.addSubview(self.titleLabel)
        self.addSubview(self.subtitleLabel)
    }
    
    func configure(with title: String,
                   subtitle: String) {
        
        self.titleLabel.setText(title)
        self.titleLabel.textAlignment = self.shouldPinLeft ? .left : .right
        self.subtitleLabel.setText(subtitle)
        self.subtitleLabel.textAlignment = self.shouldPinLeft ? .left : .right
        
        self.layoutNow()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        self.titleLabel.setSize(withWidth: 200)
        self.subtitleLabel.setSize(withWidth: 200)
        
        self.height = self.titleLabel.height + Theme.ContentOffset.short.value + self.subtitleLabel.height
        self.width = self.titleLabel.width > self.subtitleLabel.width ? self.titleLabel.width : self.subtitleLabel.width

        if self.shouldPinLeft {
            self.titleLabel.pin(.left)
            self.subtitleLabel.pin(.left)
        } else {
            self.titleLabel.pin(.right)
            self.subtitleLabel.pin(.right)
        }
        
        self.detailDisclosure.squaredSize = 18
        self.detailDisclosure.centerY = self.titleLabel.centerY
        self.detailDisclosure.match(.left, to: .right, of: self.titleLabel, offset: .short)
        
        self.titleLabel.pin(.top)
        self.subtitleLabel.pin(.bottom)
    }
}

