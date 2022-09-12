//
//  MomentReactionsView.swift
//  Jibber
//
//  Created by Benji Dodgson on 8/20/22.
//  Copyright © 2022 Benjamin Dodgson. All rights reserved.
//

import Foundation
import Combine

class MomentReactionsView: BaseView {
    
    let button = ThemeButton()
    let reactionsView = ReactionsView()
    private let badgeView = BadgeCounterView()
    
    private(set) var controller: ConversationController?
    private var subscriptions = Set<AnyCancellable>()

    override func initializeSubviews() {
        super.initializeSubviews()
        
        self.addSubview(self.reactionsView)
        self.reactionsView.expressionVideoView.shouldPlay = true 
        
        self.addSubview(self.button)
        let pointSize: CGFloat = 26
        
        self.button.set(style: .image(symbol: .faceSmiling,
                                      palletteColors: [.whiteWithAlpha],
                                      pointSize: pointSize,
                                      backgroundColor: .clear))
        
        self.button.isHidden = true
        
        self.addSubview(self.badgeView)
        self.badgeView.minToShow = 1
        
        self.clipsToBounds = false
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        self.reactionsView.expandToSuperviewSize()
        self.button.expandToSuperviewSize()
        
        self.badgeView.center = CGPoint(x: self.width - 2,
                                        y: self.height - 2)
    }
    
    func configure(with moment: Moment) {
        
        self.subscriptions.forEach { subscription in
            subscription.cancel()
        }
        
        self.controller = ConversationController.controller(for: moment.commentsId)
        let expressions = self.controller?.conversation?.expressions ?? []
        
        self.badgeView.set(value: expressions.count)
        
        if !expressions.isEmpty {
            self.reactionsView.set(expressions: expressions)
            self.reactionsView.isHidden = false
            self.button.isHidden = true
        } else {
            self.button.isHidden = false
            self.reactionsView.isHidden = true
        }
        
        self.controller?.channelChangePublisher.mainSink(receiveValue: { [unowned self] _ in
            let expressions = self.controller?.conversation?.expressions ?? []
            self.badgeView.set(value: expressions.count)
            
            if !expressions.isEmpty {
                self.reactionsView.set(expressions: expressions)
                self.reactionsView.isHidden = false
                self.button.isHidden = true
            } else {
                self.button.isHidden = false
                self.reactionsView.isHidden = true
            }
            
        }).store(in: &self.subscriptions)
    }
}
