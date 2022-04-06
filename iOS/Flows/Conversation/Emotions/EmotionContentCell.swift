//
//  EmotionContentCell.swift
//  Jibber
//
//  Created by Benji Dodgson on 4/5/22.
//  Copyright © 2022 Benjamin Dodgson. All rights reserved.
//

import Foundation

class EmotionContentCell: CollectionViewManagerCell, ManageableCell {
    typealias ItemType = Emotion
    
    var currentItem: Emotion?
    
    func configure(with item: Emotion) {
        //self.setNeedsUpdateConfiguration()
        self.contentView.set(backgroundColor: .red)
    }
}
