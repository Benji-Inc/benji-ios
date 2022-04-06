//
//  EmotionContentCell.swift
//  Jibber
//
//  Created by Benji Dodgson on 4/5/22.
//  Copyright © 2022 Benjamin Dodgson. All rights reserved.
//

import Foundation
import Localization

struct EmotionContentModel: Hashable {
    var emotion: Emotion?
}

class EmotionContentCell: CollectionViewManagerCell, ManageableCell {
    typealias ItemType = EmotionContentModel
    
    var currentItem: EmotionContentModel?
    
    let label = ThemeLabel(font: .medium)
    let emotionLabel = ThemeLabel(font: .smallBold)
    
    override func initializeSubviews() {
        super.initializeSubviews()
        
        self.contentView.addSubview(self.label)
        self.contentView.layer.cornerRadius = Theme.cornerRadius
        self.contentView.clipsToBounds = true
        self.contentView.layer.borderWidth = 2

        self.label.textAlignment = .center
        
        self.contentView.addSubview(self.emotionLabel)
    }
    
    func configure(with item: EmotionContentModel) {
        if let emotion = item.emotion {
            
            let text = localized(emotion.definition).firstCapitalized
            let color = emotion.color

            self.label.setText(text)
            self.label.textColor = color
            self.label.alpha = 1.0
            self.contentView.layer.borderColor = color.cgColor
            self.contentView.backgroundColor = color.withAlphaComponent(0.2)
            
            self.emotionLabel.setText("(\(emotion.rawValue))")
            self.emotionLabel.textColor = color
            
        } else {
            self.emotionLabel.setText("")
            self.label.setText("Select an emotion below to show what it means")
            self.label.setTextColor(.T1)
            self.label.alpha = 0.2
            self.contentView.set(backgroundColor: .clear)
            self.contentView.layer.borderColor = ThemeColor.T1.color.withAlphaComponent(0.2).cgColor
        }
        
        self.setNeedsLayout()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        self.label.setSize(withWidth: self.contentView.width * 0.8)
        self.label.centerOnXAndY()
        
        self.emotionLabel.setSize(withWidth: self.contentView.width)
        self.emotionLabel.centerOnX()
        self.emotionLabel.match(.bottom, to: .top, of: self.label, offset: .negative(.standard))
    }
}
