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

    override func initializeSubviews() {
        super.initializeSubviews()

        self.addSubview(self.readView)
        self.addSubview(self.replySummary)
    }
    
    func configure(for message: Messageable) {
        self.readView.configure(with: message)
        self.replySummary.configure(for: message)
        self.layoutNow()
    }
        
    override func layoutSubviews() {
        super.layoutSubviews()
        
        self.readView.pin(.right)
        self.readView.pin(.top)

        self.replySummary.width = self.width - self.readView.width - Theme.ContentOffset.short.value
        self.replySummary.pin(.left)
        self.replySummary.pin(.top)
    }

    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        // Only handle touches on the reply and read views.
        let replyPoint = self.convert(point, to: self.replySummary)
        let readPoint = self.convert(point, to: self.readView)

        return self.replySummary.point(inside: replyPoint, with: event)
        || self.readView.point(inside: readPoint, with: event)
    }
}
