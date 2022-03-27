//
//  EmotionCell.swift
//  Jibber
//
//  Created by Benji Dodgson on 3/27/22.
//  Copyright © 2022 Benjamin Dodgson. All rights reserved.
//

import Foundation

class EmotionCell: CollectionViewManagerCell, ManageableCell {
    typealias ItemType = Emotion
    
    var currentItem: Emotion?
    
    func configure(with item: Emotion) {
        
    }
}
