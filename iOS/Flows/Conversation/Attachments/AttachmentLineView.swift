//
//  AttachmentLineView.swift
//  Jibber
//
//  Created by Benji Dodgson on 3/18/22.
//  Copyright © 2022 Benjamin Dodgson. All rights reserved.
//

import Foundation

class AttachmentLineView: UICollectionReusableView {
    
    let lineView = BaseView()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.initializeViews()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        self.initializeViews()
    }
    
    func initializeViews() {
        
        self.addSubview(self.lineView)
        self.lineView.set(backgroundColor: .B1)
        self.lineView.alpha = 0.5
        self.clipsToBounds = false 
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        self.lineView.height = 1
        self.lineView.width = self.width + Theme.ContentOffset.xtraLong.value.doubled
        
        self.lineView.centerOnXAndY()
    }
}
