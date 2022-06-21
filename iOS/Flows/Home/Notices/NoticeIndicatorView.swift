//
//  NoticeIndicatorView.swift
//  Jibber
//
//  Created by Benji Dodgson on 6/21/22.
//  Copyright © 2022 Benjamin Dodgson. All rights reserved.
//

import Foundation
import ScrollCounter

class NoticeIndicatorView: BaseView {
    
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
        
        self.addSubview(self.counter)
        self.set(backgroundColor: .D6)
        
        NoticeStore.shared.$notices.mainSink { [unowned self] notices in
            self.counter.setValue(Float(notices.count))
        }.store(in: &self.cancellables)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        self.counter.sizeToFit()

        self.width = self.counter.width + Theme.ContentOffset.standard.value
        self.height = self.counter.height + Theme.ContentOffset.standard.value
        
        self.makeRound()
        
        self.counter.centerOnXAndY()
    }
}
