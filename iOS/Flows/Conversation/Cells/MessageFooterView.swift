//
//  MessageFooterView.swift
//  Jibber
//
//  Created by Benji Dodgson on 3/30/22.
//  Copyright © 2022 Benjamin Dodgson. All rights reserved.
//

import Foundation
import StreamChat
import ScrollCounter

class MessageFooterView: BaseView {
    
    static let height: CGFloat = 25
    
    let stackedView = StackedPersonView()
        
    let counter = NumberScrollCounter(value: 0,
                                      scrollDuration: Theme.animationDurationFast,
                                      decimalPlaces: 0,
                                      prefix: nil,
                                      suffix: nil,
                                      seperator: "",
                                      seperatorSpacing: 0,
                                      font: FontType.regular.font,
                                      textColor: ThemeColor.T1.color,
                                      animateInitialValue: true,
                                      gradientColor: ThemeColor.B0.color,
                                      gradientStop: 4)
    
    override func initializeSubviews() {
        super.initializeSubviews()
        
        self.addSubview(self.stackedView)
        self.set(backgroundColor: .red)
    }
    
    func configure(for message: Messageable) {
        
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        self.stackedView.pin(.left)
        self.stackedView.centerOnY()
        
        self.counter.sizeToFit()
        self.counter.pin(.right)
        self.counter.centerOnY()
    }
}
