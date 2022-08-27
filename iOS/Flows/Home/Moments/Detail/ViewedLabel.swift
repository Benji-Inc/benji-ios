//
//  ViewedLabel.swift
//  Jibber
//
//  Created by Benji Dodgson on 8/27/22.
//  Copyright © 2022 Benjamin Dodgson. All rights reserved.
//

import Foundation
import Combine
import ScrollCounter

class ViewedLabel: BaseView {
    
    private var controller: MessageSequenceController?
    private var subscriptions = Set<AnyCancellable>()
    
    var imageView = SymbolImageView(symbol: .eye)
    var counter = NumberScrollCounter(value: 0,
                                      scrollDuration: Theme.animationDurationSlow,
                                      decimalPlaces: 0,
                                      prefix: "",
                                      suffix: nil,
                                      seperator: "",
                                      seperatorSpacing: 0,
                                      font: FontType.smallBold.font,
                                      textColor: ThemeColor.whiteWithAlpha.color,
                                      animateInitialValue: true,
                                      gradientColor: nil,
                                      gradientStop: nil)
        
    override func initializeSubviews() {
        super.initializeSubviews()
        
        self.addSubview(self.counter)
        self.addSubview(self.imageView)
        
        self.imageView.setPoint(size: 20)
        self.imageView.tintColor = ThemeColor.whiteWithAlpha.color
    }
    
    func configure(with moment: Moment) {
        self.subscriptions.forEach { subscription in
            subscription.cancel()
        }
        
        self.controller = ConversationController.controller(for: moment.commentsId)
        
        if let count = self.controller?.memberCount {
            self.counter.setValue(Float(count), animated: true)
            self.counter.isVisible = count > 0
        }
                
        self.controller?.messageSequenceChangePublisher.mainSink(receiveValue: { [unowned self] _ in
            if let count = self.controller?.memberCount {
                self.counter.setValue(Float(count), animated: true)
                self.counter.isVisible = count > 0
            }
        }).store(in: &self.subscriptions)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        self.height = 25
        
        self.counter.sizeToFit()
        self.counter.pin(.right)
        self.counter.centerOnY()
        
        self.imageView.squaredSize = 25
        self.imageView.match(.right, to: .left, of: self.counter, offset: .negative(.short))
        self.imageView.centerOnY()
        
        let proposedWidth = self.counter.width + self.imageView.width
        
        self.width = clamp(proposedWidth, 50, 100)
    }
}
