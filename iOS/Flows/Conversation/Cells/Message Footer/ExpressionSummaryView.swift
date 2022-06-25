//
//  ExpressionSummaryView.swift
//  Jibber
//
//  Created by Benji Dodgson on 6/24/22.
//  Copyright © 2022 Benjamin Dodgson. All rights reserved.
//

import Foundation

class ExpressionSummaryView: BaseView, MessageConfigureable {
    
    let label = ThemeLabel(font: .small, textColor: .whiteWithAlpha)
    
    override func initializeSubviews() {
        super.initializeSubviews()
        
        self.addSubview(self.label)
        self.label.textAlignment = .center
    }
    
    func configure(for message: Messageable) {
        self.label.setText("Coming soon...")
        self.layoutNow()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        self.label.setSize(withWidth: self.width)
        self.label.centerOnXAndY()
    }
}
