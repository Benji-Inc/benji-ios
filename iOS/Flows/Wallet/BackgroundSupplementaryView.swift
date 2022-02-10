//
//  TransactionsBackgroundView.swift
//  Jibber
//
//  Created by Benji Dodgson on 2/8/22.
//  Copyright © 2022 Benjamin Dodgson. All rights reserved.
//

import Foundation

class BackgroundSupplementaryView: UICollectionReusableView, ElementKind {
    
    static var kind: String = "background"
    
    private let backgroundView = BackgroundGradientView()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        self.layer.cornerRadius = Theme.cornerRadius
        self.addSubview(self.backgroundView)
        self.clipsToBounds = true
        self.layer.masksToBounds = true
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        self.backgroundView.expandToSuperviewSize()
    }
}
