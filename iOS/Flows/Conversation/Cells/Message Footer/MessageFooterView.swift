//
//  MessageFooterView.swift
//  Jibber
//
//  Created by Benji Dodgson on 3/30/22.
//  Copyright © 2022 Benjamin Dodgson. All rights reserved.
//

import Foundation
import Combine

class MessageFooterView: BaseView {
    
    static let height: CGFloat = 94
    static let collapsedHeight: CGFloat = 30 

    let replySummary = MessageSummaryView()
    
    var didTapViewReplies: CompletionOptional = nil
    
    let replyButton = ReplyButton()
    let statusLabel = ThemeLabel(font: .small, textColor: .whiteWithAlpha)
    
    let expressionStackedView = StackedExpressionView()
    lazy var quickExpressionsView = FavoriteExpressionsView()
            
    private(set) var message: Messageable?

    override func initializeSubviews() {
        super.initializeSubviews()
                
        self.addSubview(self.statusLabel)
        self.statusLabel.textAlignment = .right
        
        self.addSubview(self.replyButton)
        self.replyButton.alpha = 0
        
        self.addSubview(self.replySummary)
        
        self.addSubview(self.expressionStackedView)
        
        self.replySummary.replyView.didSelect { [unowned self] in
            self.didTapViewReplies?()
        }
        
        self.expressionStackedView.didTapAdd = { [unowned self] in
            Task {
                if self.quickExpressionsView.superview.isNil {
                    await self.quickExpressionsView.reveal(in: self)
                } else {
                    await self.quickExpressionsView.dismiss()
                }
            }
        }
    }
    
    func configure(for message: Messageable) {
        self.message = message
        
        self.replyButton.isVisible = !message.isReply
        self.replySummary.configure(for: message)
        self.expressionStackedView.configure(with: message)
        self.updateStatus(for: message)
        self.layoutNow()
    }
        
    override func layoutSubviews() {
        super.layoutSubviews()
        
        self.replyButton.pin(.top)
        self.replyButton.pin(.right)
        
        self.expressionStackedView.pin(.top)
        self.expressionStackedView.pin(.left)
        
        self.replySummary.width = self.width
        self.replySummary.height = self.height - self.replyButton.height - Theme.ContentOffset.long.value
        self.replySummary.match(.top, to: .bottom, of: self.replyButton, offset: .long)
        self.replySummary.pin(.left)
        
        self.statusLabel.setSize(withWidth: self.width)
        self.statusLabel.pin(.top, offset: .short)
        self.statusLabel.pin(.right)
        
        self.quickExpressionsView.match(.bottom, to: .top, of: self.expressionStackedView, offset: .negative(.standard))
        self.quickExpressionsView.pin(.left)
    }

    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        // Only handle touches on the view that are present.
        let replyPoint = self.convert(point, to: self.replySummary)
        let replyButtonPoint = self.convert(point, to: self.replyButton)
        let expressionPoint = self.convert(point, to: self.expressionStackedView)
        let quickPoint = self.convert(point, to: self.quickExpressionsView)

        return self.replySummary.point(inside: replyPoint, with: event)
        || self.replyButton.point(inside: replyButtonPoint, with: event)
        || self.expressionStackedView.point(inside: expressionPoint, with: event)
        || self.quickExpressionsView.point(inside: quickPoint, with: event)
    }

    private func getString(for deliveryStatus: DeliveryStatus) -> String {
        switch deliveryStatus {
        case .sending:
            return "sending..."
        case .sent,.reading, .read:
            return "sent"
        case .error:
            return "failed to send"
        }
    }
    
    private func updateStatus(for message: Messageable) {
        
        UIView.animate(withDuration: Theme.animationDurationFast) {
            switch message.deliveryStatus {
            case .sending, .error:
                self.statusLabel.text = self.getString(for: message.deliveryStatus)
                self.statusLabel.alpha = 1
                self.replyButton.alpha = 0
                if message.deliveryStatus == .sending {
                    self.statusLabel.textColor =  ThemeColor.whiteWithAlpha.color
                    self.statusLabel.font = FontType.small.font
                } else {
                    self.statusLabel.textColor = ThemeColor.red.color
                    self.statusLabel.font = FontType.smallBold.font
                }
            case .sent, .reading, .read:
                self.statusLabel.alpha = 0
                self.replyButton.alpha = 1.0
            }
            self.layoutNow()
        }
    }
}
