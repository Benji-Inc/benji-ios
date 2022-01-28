//
//  NewConversationCell.swift
//  Jibber
//
//  Created by Martin Young on 12/16/21.
//  Copyright © 2021 Benjamin Dodgson. All rights reserved.
//

import Foundation

class PlaceholderConversationCell: UICollectionViewCell, ConversationUIStateSettable {

    override init(frame: CGRect) {
        super.init(frame: frame)

        self.initializeViews()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)

        self.initializeViews()
    }

    private func initializeViews() {
        
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        
    }
    
    func set(state: ConversationUIState) {
        self.setNeedsLayout()
    }
    
    override func apply(_ layoutAttributes: UICollectionViewLayoutAttributes) {
        super.apply(layoutAttributes)
        
        self.alpha = 1.0
    }
}
