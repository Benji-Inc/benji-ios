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
    
    let readView = ReadIndicatorView()
    let replySummary = ReplySummaryView()
        
    override func initializeSubviews() {
        super.initializeSubviews()
        
        self.addSubview(self.readView)
        self.addSubview(self.replySummary)
    }
    
    func configure(for message: Messageable) {
        self.readView.configure(with: message)
        self.replySummary.configure(for: message)
    }
        
    override func layoutSubviews() {
        super.layoutSubviews()
        
        self.readView.pin(.right)
        self.readView.pin(.top)
        
        self.replySummary.height = MessageFooterView.height
        self.replySummary.width = self.width - self.readView.width
        self.replySummary.pin(.left)
        self.replySummary.pin(.top)
    }
}
