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
    
    static let minimumHeight: CGFloat = 26
    static let maxHeight: CGFloat = 58

    override func initializeSubviews() {
        super.initializeSubviews()
        
        self.addSubview(self.personView)
        self.addSubview(self.label)
        self.label.lineBreakMode = .byTruncatingTail
        
        self.addSubview(self.dateLabel)
        
        self.addSubview(self.imageView)
        self.imageView.contentMode = .scaleAspectFit
        self.imageView.tintColor = ThemeColor.white.color
        
        self.dateLabel.alpha = 0.25
        self.imageView.alpha = 0.25
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        
        self.personView.squaredSize = MessagePreview.minimumHeight
        self.personView.pin(.left)
        self.personView.pin(.top)
        
        self.imageView.squaredSize = 8
        self.imageView.match(.left, to: .right, of: self.personView, offset: .standard)

        self.dateLabel.setSize(withWidth: self.width - self.personView.width - Theme.ContentOffset.standard.value)
        self.dateLabel.match(.top, to: .top, of: self.personView)
        self.dateLabel.match(.left, to: .right, of: self.imageView, offset: .custom(2))
        
        self.imageView.centerY = self.dateLabel.centerY

        let maxLabelHeight = MessagePreview.maxHeight - self.dateLabel.height - Theme.ContentOffset.short.value
        self.label.setSize(withWidth: self.width - self.personView.width - Theme.ContentOffset.standard.value, height: maxLabelHeight)
        self.label.match(.top, to: .bottom, of: self.dateLabel, offset: .short)
        self.label.match(.left, to: .right, of: self.personView, offset: .standard)
        
        self.height = clamp(self.label.bottom, MessagePreview.minimumHeight, MessagePreview.maxHeight)
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
        
        self.imageView.set(symbol: message.deliveryType.symbol)
        
        self.personView.set(info: message.authorExpression,
                            author: message.authorId,
                            defaultColors: [.B0, .B1])
        self.dateLabel.configure(with: message)
        self.layoutNow()
    }
}
