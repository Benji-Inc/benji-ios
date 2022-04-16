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
    
    let stackedView = StackedPersonView()
    let replySummary = ReplySummaryView()
        
    override func initializeSubviews() {
        super.initializeSubviews()
        
        self.set(backgroundColor: .red)
        self.addSubview(self.stackedView)
        self.addSubview(self.replySummary)
    }
    
    func configure(for message: Messageable) {
        self.stackedView.configure(with: message.nonMeConsumers)
        self.replySummary.configure(for: message)
    }
        
    override func layoutSubviews() {
        super.layoutSubviews()
        
        self.stackedView.pin(.right)
        self.stackedView.pin(.top)
        
        self.replySummary.height = MessageFooterView.height
        self.replySummary.expandToSuperviewWidth()
        self.replySummary.pin(.left)
        self.replySummary.pin(.top)
    }
}
