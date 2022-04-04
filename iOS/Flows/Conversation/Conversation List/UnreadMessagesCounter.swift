//
//  UnreadMessagesCounter.swift
//  Jibber
//
//  Created by Benji Dodgson on 4/4/22.
//  Copyright © 2022 Benjamin Dodgson. All rights reserved.
//

import Foundation
import ScrollCounter

class UnreadMessagesCounter: BaseView {
    
    let counter = NumberScrollCounter(value: 0,
                                      scrollDuration: Theme.animationDurationSlow,
                                      decimalPlaces: 0,
                                      prefix: "",
                                      suffix: nil,
                                      seperator: "",
                                      seperatorSpacing: 0,
                                      font: FontType.small.font,
                                      textColor: ThemeColor.T1.color,
                                      animateInitialValue: true,
                                      gradientColor: nil,
                                      gradientStop: nil)
    
    override func initializeSubviews() {
        super.initializeSubviews()
        
        self.set(backgroundColor: .D6)
        self.addSubview(self.counter)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        self.squaredSize = 30
        self.makeRound()
        
        self.counter.sizeToFit()
        self.counter.centerOnXAndY()
    }
}
