//
//  MessageFooterView.swift
//  Jibber
//
//  Created by Benji Dodgson on 3/30/22.
//  Copyright © 2022 Benjamin Dodgson. All rights reserved.
//

import Foundation
import StreamChat
import Combine

class MessageFooterView: BaseView {
    
    static let height: CGFloat = 70
    static let collapsedHeight: CGFloat = 30 

    let replySummary = ReplySummaryView()
    let readView = ReadIndicatorView()
    let statusLabel = ThemeLabel(font: .small, textColor: .white)

    override func initializeSubviews() {
        super.initializeSubviews()

        self.addSubview(self.readView)
        self.addSubview(self.replySummary)
        self.addSubview(self.statusLabel)
    }
    
    func configure(for message: Messageable) {
        self.readView.configure(with: message)
        self.replySummary.configure(for: message)

        UIView.animate(withDuration: Theme.animationDurationFast) {
            switch message.deliveryStatus {
            case .sending, .error:
                self.statusLabel.text = self.getString(for: message.deliveryStatus)
                self.readView.alpha = 0
                self.statusLabel.alpha = 1
                if message.deliveryStatus == .sending {
                    self.statusLabel.textColor =  ThemeColor.white.color
                    self.statusLabel.font = FontType.small.font
                } else {
                    self.statusLabel.textColor = ThemeColor.red.color
                    self.statusLabel.font = FontType.smallBold.font
                }
            case .sent, .reading, .read:
                self.readView.alpha = 1
                self.statusLabel.alpha = 0
            }
            self.layoutNow()
        }
    }
        
    override func layoutSubviews() {
        super.layoutSubviews()

        self.replySummary.width = self.width - self.readView.width - Theme.ContentOffset.short.value
        self.replySummary.pin(.left)
        self.replySummary.pin(.top)

        self.readView.pin(.right)
        self.readView.pin(.top)

        self.statusLabel.setSize(withWidth: self.width)
        self.statusLabel.pin(.top)
        self.statusLabel.pin(.right)
    }

    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        // Only handle touches on the reply and read views.
        let replyPoint = self.convert(point, to: self.replySummary)
        let readPoint = self.convert(point, to: self.readView)

        return self.replySummary.point(inside: replyPoint, with: event)
        || self.readView.point(inside: readPoint, with: event)
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
}
