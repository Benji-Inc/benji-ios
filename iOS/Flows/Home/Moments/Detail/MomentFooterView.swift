//
//  MomentFooterView.swift
//  Jibber
//
//  Created by Benji Dodgson on 8/30/22.
//  Copyright © 2022 Benjamin Dodgson. All rights reserved.
//

import Foundation

class MomentFooterView: BaseView {
    
    let commentsLabel = CommentsLabel()
    let reactionsView = MomentReactionsView()
    private var moment: Moment?
    
    override func initializeSubviews() {
        super.initializeSubviews()
        
        self.addSubview(self.commentsLabel)
        self.addSubview(self.reactionsView)
    }
    
    func configure(for moment: Moment) {
        self.moment = moment
        self.commentsLabel.configure(with: moment)
        self.reactionsView.configure(with: moment)
        self.layoutNow()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        self.reactionsView.squaredSize = 35
        self.reactionsView.pinToSafeAreaRight()
        
        let maxLabelWidth = Theme.getPaddedWidth(with: self.width) - self.reactionsView.width - Theme.ContentOffset.long.value
        self.commentsLabel.setSize(withWidth: maxLabelWidth)
        self.commentsLabel.pin(.top, offset: .xtraLong)
        self.commentsLabel.pinToSafeAreaLeft()
        
        self.reactionsView.centerY = self.commentsLabel.centerY
    }
}
