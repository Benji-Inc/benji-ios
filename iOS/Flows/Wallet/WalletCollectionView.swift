//
//  WalletCollectionView.swift
//  Jibber
//
//  Created by Benji Dodgson on 2/4/22.
//  Copyright © 2022 Benjamin Dodgson. All rights reserved.
//

import Foundation

class WalletCollectionView: CollectionView {
    
    private let gradientView = BackgroundGradientView()
    
    init() {
        super.init(layout: WalletCollectionViewLayout())
        self.addSubview(self.gradientView)
        self.layer.cornerRadius = Theme.cornerRadius
        self.clipsToBounds = true
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        self.gradientView.expandToSuperviewSize()
    }
}
