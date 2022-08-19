//
//  CommentsBadgeView.swift
//  Jibber
//
//  Created by Benji Dodgson on 8/19/22.
//  Copyright © 2022 Benjamin Dodgson. All rights reserved.
//

import Foundation
import Combine
import ScrollCounter

class CommentsButton: ThemeButton {
    
    private var controller: MessageSequenceController?
    private var subscriptions = Set<AnyCancellable>()
    
    var counter = NumberScrollCounter(value: 0,
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
        
        let pointSize: CGFloat = 22
        
        self.set(style: .image(symbol: .rectangleStack,
                               palletteColors: [.white],
                               pointSize: pointSize,
                               backgroundColor: .clear))
        
        self.showShadow(withOffset: 0, opacity: 1.0)
        
        self.clipsToBounds = false
    }
    
    func configure(with moment: Moment) {
        self.subscriptions.forEach { subscription in
            subscription.cancel()
        }
        
        self.controller = JibberChatClient.shared.conversationController(for: moment.commentsId)
        
        self.counter.setValue(Float(10))
        
        self.controller?.messageSequenceChangePublisher.mainSink(receiveValue: { [unowned self] _ in
            guard let sequence = self.controller?.messageSequence else { return }
            self.counter.setValue(Float(sequence.totalUnread))
        }).store(in: &self.subscriptions)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        self.counter.sizeToFit()
        self.counter.centerX = self.halfWidth - 1
        self.counter.top = self.height - 4
    }
}
