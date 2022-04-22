//
//  MessageReadView.swift
//  Jibber
//
//  Created by Benji Dodgson on 4/19/22.
//  Copyright © 2022 Benjamin Dodgson. All rights reserved.
//

import Foundation
import ScrollCounter

class ReadIndicatorView: BaseView {
    
    private let imageView = UIImageView(image: UIImage(systemName: "eyeglasses"))
    private let counter = NumberScrollCounter(value: 0,
                                              scrollDuration: Theme.animationDurationSlow,
                                              decimalPlaces: 0,
                                              prefix: "",
                                              suffix: nil,
                                              seperator: "",
                                              seperatorSpacing: 0,
                                              font: FontType.small.font,
                                              textColor: ThemeColor.white.color,
                                              animateInitialValue: true,
                                              gradientColor: nil,
                                              gradientStop: nil)
    
    override func initializeSubviews() {
        super.initializeSubviews()

        self.height = 20

        self.addSubview(self.imageView)
        self.addSubview(self.counter)
        
        self.layer.cornerRadius = Theme.innerCornerRadius
        self.layer.borderColor = ThemeColor.BORDER.color.cgColor
        self.layer.borderWidth = 0.5
        
        self.imageView.tintColor = ThemeColor.whiteWithAlpha.color
        self.imageView.contentMode = .scaleAspectFit
    }
    
    func configure(with message: Messageable) {
        UIView.animate(withDuration: Theme.animationDurationSlow) {
             if message.canBeConsumed {
                 self.set(backgroundColor: .D6)
                 self.counter.isVisible = false
                 self.imageView.tintColor = ThemeColor.white.color
             } else if !message.isFromCurrentUser,
                        message.isConsumedByMe,
                        message.hasBeenConsumedBy.count == 1 {
                 self.counter.isVisible = false
                 self.imageView.tintColor = ThemeColor.whiteWithAlpha.color
                 self.set(backgroundColor: .clear)
             } else {
                 self.counter.isVisible = true
                 self.counter.alpha = 0.35
                 self.imageView.tintColor = ThemeColor.whiteWithAlpha.color
                 self.set(backgroundColor: .clear)
             }
            self.setNeedsLayout()
        } completion: { _ in
            if self.counter.isVisible {
                self.counter.setValue(Float(message.nonMeConsumers.count), animated: true)
            }
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()

        self.imageView.size = CGSize(width: 22, height: 10)
        self.imageView.centerOnY()
        
        self.counter.sizeToFit()
        self.counter.centerOnY()
        
        if self.counter.isVisible {
            self.width
            = Theme.ContentOffset.short.value.doubled + self.imageView.width
            + self.counter.width + Theme.ContentOffset.short.value
        } else {
            self.width = Theme.ContentOffset.short.value.doubled + self.imageView.width
        }
        
        self.imageView.pin(.left, offset: .short)
        self.counter.match(.left, to: .right, of: self.imageView, offset: .short)
    }
}
