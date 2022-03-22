//
//  SectionBackgroundView.swift
//  Jibber
//
//  Created by Benji Dodgson on 3/21/22.
//  Copyright © 2022 Benjamin Dodgson. All rights reserved.
//

import Foundation

class SectionBackgroundView: UICollectionReusableView, ElementKind {
    
    static var kind: String = "background"
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.initializeViews()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func initializeViews() {
        self.set(backgroundColor: .B6)
        
        self.layer.cornerRadius = Theme.cornerRadius
        self.clipsToBounds = true
    }
}
