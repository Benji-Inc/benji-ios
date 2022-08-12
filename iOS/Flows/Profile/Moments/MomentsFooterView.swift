//
//  MomentsFooterView.swift
//  Jibber
//
//  Created by Benji Dodgson on 8/11/22.
//  Copyright © 2022 Benjamin Dodgson. All rights reserved.
//

import Foundation

class MomentsFooterView: UICollectionReusableView {
    
    let timeLabel = ThemeLabel(font: .regular)
        
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.initializeViews()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        self.initializeViews()
    }
    
    func initializeViews() {
        self.addSubview(self.timeLabel)
        self.timeLabel.setText("Last 14 Days")
        self.timeLabel.textAlignment = .center
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        self.timeLabel.setSize(withWidth: Theme.getPaddedWidth(with: self.width))
        self.timeLabel.centerOnXAndY()
    }
}
