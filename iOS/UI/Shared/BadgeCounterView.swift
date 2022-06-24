//
//  BadgeCounterView.swift
//  Jibber
//
//  Created by Benji Dodgson on 6/23/22.
//  Copyright © 2022 Benjamin Dodgson. All rights reserved.
//

import Foundation
import ScrollCounter

class BadgeCounterView: BaseView {
    
    let counter = NumberScrollCounter(value: 0,
                                      scrollDuration: Theme.animationDurationSlow,
                                      decimalPlaces: 0,
                                      prefix: "",
                                      suffix: nil,
                                      seperator: "",
                                      seperatorSpacing: 0,
                                      font: FontType.xtraSmall.font,
                                      textColor: ThemeColor.white.color,
                                      animateInitialValue: true,
                                      gradientColor: nil,
                                      gradientStop: nil)
    
    override func initializeSubviews() {
        super.initializeSubviews()
        
        self.addSubview(self.counter)
        self.set(backgroundColor: .D6)
        
        self.alpha = 0
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        self.counter.sizeToFit()
        
        self.width = self.counter.width + Theme.ContentOffset.short.value
        self.height = self.counter.height + Theme.ContentOffset.short.value
        
        if self.width < self.height {
            self.width = self.height
        }
        
        self.makeRound()
        self.showShadow(withOffset: 0, opacity: 1.0, color: .red)
        
        self.counter.centerOnXAndY()
    }
    
    func animateChanges(shouldShow: Bool) {
        Task {
            await UIView.awaitSpringAnimation(with: .fast, animations: { [unowned self] in
                if shouldShow {
                    self.transform = .identity
                    self.alpha = 1.0
                } else {
                    self.alpha = 0.0
                }
            })
        }
    }
}