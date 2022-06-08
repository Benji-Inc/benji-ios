//
//  File.swift
//  Jibber
//
//  Created by Benji Dodgson on 11/6/21.
//  Copyright © 2021 Benjamin Dodgson. All rights reserved.
//

import Foundation
import UIKit

class ToastStatusView: ToastView {

    private let imageView = SymbolImageView()
    private let label = ThemeLabel(font: .regular)
    private let blurView = BlurView()

    override func initializeSubviews() {
        super.initializeSubviews()

        self.addSubview(self.blurView)
        self.addSubview(self.imageView)
        self.imageView.contentMode = .scaleAspectFit
        
        if let symbol = self.toast.displayable as? ImageSymbol {
            self.imageView.set(symbol: symbol)
        } else {
            self.imageView.image = self.toast.displayable.image
        }
        
        self.addSubview(self.label)
        
        if self.toast.type == .success {
            self.backgroundColor = ThemeColor.D6.color.withAlphaComponent(0.2)
            self.label.setTextColor(.white)
        } else {
            self.backgroundColor = ThemeColor.red.color.withAlphaComponent(0.2)
            self.imageView.tintColor = ThemeColor.red.color
            self.label.setTextColor(.red)
        }

        self.label.setText(self.toast.description)
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        #if !NOTIFICATION
        guard let superview = UIWindow.topWindow() else { return }
        let imageSize: CGFloat = 24
        
        let maxWidth = superview.width - (Theme.ContentOffset.xtraLong.value * 3) - imageSize
        self.label.setSize(withWidth: maxWidth)
        
        self.imageView.squaredSize = imageSize
        
        let width = self.label.width + Theme.ContentOffset.long.value.doubled + self.imageView.width + Theme.ContentOffset.long.value
        self.size = CGSize(width: width,
                           height: self.label.height + Theme.ContentOffset.long.value.doubled)

        self.imageView.centerOnY()
        self.imageView.pin(.left, offset: .long)

        self.label.match(.left, to: .right, of: self.imageView, offset: .long)
        self.label.centerOnY()
        
        self.centerOnX()
        
        self.blurView.expandToSuperviewSize()

        #endif
    }
}
