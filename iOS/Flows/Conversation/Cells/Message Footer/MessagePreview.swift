//
//  MessagePreview.swift
//  Jibber
//
//  Created by Benji Dodgson on 4/26/22.
//  Copyright © 2022 Benjamin Dodgson. All rights reserved.
//

import Foundation

class MessagePreview: BaseView {

    let personView = PersonGradientView()
    let dateLabel = MessageDateLabel(font: .xtraSmall)
    let label = ThemeLabel(font: .small)
    let imageView = SymbolImageView()
    let mainContentArea = BaseView()
    let blurView = BlurView()
    
    static let minimumHeight: CGFloat = 26

    override func initializeSubviews() {
        super.initializeSubviews()
        
        self.addSubview(self.blurView)
        self.addSubview(self.mainContentArea)
        
        self.mainContentArea.addSubview(self.personView)
        self.mainContentArea.addSubview(self.label)
        self.label.lineBreakMode = .byTruncatingTail
        
        self.mainContentArea.addSubview(self.dateLabel)
        
        self.mainContentArea.addSubview(self.imageView)
        self.imageView.contentMode = .scaleAspectFit
        self.imageView.tintColor = ThemeColor.white.color
        
        self.dateLabel.alpha = 0.25
        self.imageView.alpha = 0.25
        
        self.showShadow(withOffset: 0, opacity: 0.3, radius: 5, color: ThemeColor.D6.color)
        self.layer.shadowOpacity = 0.0
        
        self.blurView.roundCorners()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        
        self.blurView.expandToSuperviewSize()
        
        let padding = Theme.ContentOffset.short
        
        self.mainContentArea.width = self.width - padding.value.doubled
        self.mainContentArea.height = self.height - padding.value.doubled
        self.mainContentArea.centerOnXAndY()
        
        self.personView.squaredSize = MessagePreview.minimumHeight
        self.personView.pin(.left)
        self.personView.pin(.top)
        
        self.imageView.squaredSize = 8
        self.imageView.match(.left, to: .right, of: self.personView, offset: padding)

        self.dateLabel.setSize(withWidth: self.width - self.personView.width - padding.value)
        self.dateLabel.match(.top, to: .top, of: self.personView)
        self.dateLabel.match(.left, to: .right, of: self.imageView, offset: .custom(2))
        
        self.imageView.centerY = self.dateLabel.centerY

        let maxHeight = self.mainContentArea.height - self.dateLabel.bottom - padding.value
        let maxWidth = self.mainContentArea.width - self.personView.width - padding.value
        self.label.setSize(withWidth: maxWidth, height: maxHeight)
        self.label.match(.top, to: .bottom, of: self.dateLabel, offset: padding)
        self.label.match(.left, to: .right, of: self.personView, offset: padding)
    }

    func configure(with message: Messageable) {
        if message.kind.hasText {
            self.label.setText(message.kind.text)
        } else if message.kind.hasImage {
            self.label.setText("Tap to view image")
        } else if message.kind.isLink {
            self.label.setText("Tap to view link")
        } else {
            self.label.setText("View reply")
        }
        
        self.layer.shadowOpacity = message.canBeConsumed ? 0.3 : 0.0
        
        self.imageView.set(symbol: message.deliveryType.symbol)
        
        self.personView.set(info: message.authorExpression,
                            authorId: message.authorId,
                            defaultColors: [.B0, .B1])
        self.dateLabel.configure(with: message)
        self.layoutNow()
    }
}
