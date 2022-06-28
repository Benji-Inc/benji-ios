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
    
    static let height: CGFloat = 86
    static let collapsedHeight: CGFloat = 30 

    let replySummary = MessageSummaryView()
    
    var didTapViewReplies: CompletionOptional = nil
    
    let replyButton = ReplyButton()
    let statusLabel = ThemeLabel(font: .small, textColor: .whiteWithAlpha)
            
    private var message: Messageable?

    override func initializeSubviews() {
        super.initializeSubviews()

        self.addSubview(self.statusLabel)
        self.statusLabel.textAlignment = .right
        
        self.addSubview(self.replyButton)
        self.replyButton.alpha = 0
        
        self.addSubview(self.replySummary)
        
        self.replySummary.replyView.didSelect { [unowned self] in
            self.didTapViewReplies?()
        }
    }
    
    func configure(for message: Messageable) {
        self.message = message
        self.replyButton.configure(for: message)
        self.replySummary.configure(for: message)
        self.updateStatus(for: message)
    }
        
    override func layoutSubviews() {
        super.layoutSubviews()
        
        self.replyButton.pin(.top)
        self.replyButton.pin(.right)
        
        self.replySummary.width = self.width - self.replyButton.width - Theme.ContentOffset.long.value
        self.replySummary.height = self.height
        self.replySummary.pin(.top)
        self.replySummary.pin(.left)
        
        self.statusLabel.setSize(withWidth: self.width)
        self.statusLabel.pin(.top, offset: .short)
        self.statusLabel.pin(.right)
    }

    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        // Only handle touches on the reply and read views.
        let replyPoint = self.convert(point, to: self.replySummary)
        let readPoint = self.convert(point, to: self.replyButton)

        return self.replySummary.point(inside: replyPoint, with: event)
        || self.replyButton.point(inside: readPoint, with: event)
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
