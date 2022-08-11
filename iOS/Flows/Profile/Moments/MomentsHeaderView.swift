//
//  MomentsHeaderView.swift
//  Jibber
//
//  Created by Benji Dodgson on 8/11/22.
//  Copyright © 2022 Benjamin Dodgson. All rights reserved.
//

import Foundation

class MomentsHeaderView: UICollectionReusableView {
    
    let leftLabel = ThemeLabel(font: .regular)
    let rightLabel = ThemeLabel(font: .small, textColor: .whiteWithAlpha)
        
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.initializeViews()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        self.initializeViews()
    }
    
    func initializeViews() {
        self.addSubview(self.leftLabel)
        self.leftLabel.setText("Last 14 Days")
        self.leftLabel.textAlignment = .left
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        self.leftLabel.setSize(withWidth: Theme.getPaddedWidth(with: self.width))
        self.leftLabel.pin(.top)
        self.leftLabel.pin(.left)
    }
}
