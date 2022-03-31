//
//  NoticeButton.swift
//  Jibber
//
//  Created by Benji Dodgson on 3/31/22.
//  Copyright © 2022 Benjamin Dodgson. All rights reserved.
//

import Foundation
import ScrollCounter

class NoticeCounterView: BaseView {
    
    let counter = NumberScrollCounter(value: 0,
                                         scrollDuration: Theme.animationDurationSlow,
                                         decimalPlaces: 0,
                                         prefix: "",
                                         suffix: nil,
                                         seperator: "",
                                         seperatorSpacing: 0,
                                         font: FontType.small.font,
                                         textColor: ThemeColor.T4.color,
                                         animateInitialValue: true,
                                         gradientColor: nil,
                                         gradientStop: nil)
    
    let circle = BaseView()
    
    override func initializeSubviews() {
        super.initializeSubviews()
        
        self.addSubview(self.circle)
        self.circle.set(backgroundColor: .B5)
        
        self.addSubview(self.counter)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        self.circle.squaredSize = self.height * 0.56
        self.circle.makeRound()
        self.circle.centerOnXAndY()
        
        self.counter.sizeToFit()
        self.counter.centerOnXAndY()
    }
}
