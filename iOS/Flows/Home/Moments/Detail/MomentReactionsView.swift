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
    
    private let button = ThemeButton()
    let reactionsView = PersonGradientView()
    private let badgeView = BadgeCounterView()
    
    private var controller: ConversationController?
    private var subscriptions = Set<AnyCancellable>()
        

    override func initializeSubviews() {
        super.initializeSubviews()
        
        self.addSubview(self.reactionsView)
        self.reactionsView.expressionVideoView.shouldPlay = true 
        
        self.addSubview(self.button)
        let pointSize: CGFloat = 26
        
        self.button.set(style: .image(symbol: .faceSmiling,
                                      palletteColors: [.white],
                                      pointSize: pointSize,
                                      backgroundColor: .clear))
        
        self.button.isHidden = true
        
        self.addSubview(self.badgeView)
        self.badgeView.set(value: 10)

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
        
        
        self.controller = JibberChatClient.shared.conversationController(for: moment.commentsId)
        if let info = self.controller?.conversation?.expressions.first {
    
            Task {
                let expression = try await Expression.getObject(with: info.expressionId)
                self.reactionsView.set(expression: expression, person: nil)
                self.reactionsView.isHidden = false
            }
            
            self.button.isHidden = true
        } else {
            self.button.isHidden = false
            self.reactionsView.isHidden = true
        }
        
        self.controller?.channelChangePublisher.mainSink(receiveValue: { [unowned self] _ in
            if let info = self.controller?.conversation?.expressions.first {
        
                Task {
                    let expression = try await Expression.getObject(with: info.expressionId)
                    self.reactionsView.set(expression: expression, person: nil)
                    self.reactionsView.isHidden = false
                }
                
                self.button.isHidden = true
            } else {
                self.button.isHidden = false
                self.reactionsView.isHidden = true
            }
        }).store(in: &self.subscriptions)
    }
}
