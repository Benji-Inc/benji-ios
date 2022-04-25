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

    let circleView = UIView()
    let emotionLabel = ThemeLabel(font: .regularBold)
    let definitionLabel = ThemeLabel(font: .regular)

    
    override func initializeSubviews() {
        super.initializeSubviews()

        self.contentView.addSubview(self.circleView)
        self.circleView.clipsToBounds = true
        self.circleView.layer.borderWidth = 2

        self.circleView.addSubview(self.definitionLabel)
        self.definitionLabel.textAlignment = .center
        
        self.circleView.addSubview(self.emotionLabel)
    }
    
    func configure(with item: EmotionContentModel) {
        if let emotion = item.emotion {
            let text = localized(emotion.definition).firstCapitalized
            let color = emotion.color

            self.definitionLabel.setText(text)
            self.definitionLabel.textColor = color
            self.definitionLabel.alpha = 1.0
            self.circleView.layer.borderColor = color.cgColor
            self.circleView.backgroundColor = color.withAlphaComponent(0.2)
            
            self.emotionLabel.setText(emotion.description)
            self.emotionLabel.textColor = color
            
        } else {
            self.emotionLabel.setText("")
            self.definitionLabel.setText("Select any emotion below to see what it means and add it to your message")
            self.definitionLabel.setTextColor(.white)
            self.definitionLabel.alpha = 0.2
            self.circleView.set(backgroundColor: .clear)
            self.circleView.layer.borderColor = ThemeColor.white.color.withAlphaComponent(0.2).cgColor
        }
        
        self.setNeedsLayout()
    }
    
    override func getHighlighetedViews() -> [UIView] {
        return []
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()

        self.circleView.squaredSize = min(self.contentView.width, self.contentView.height)
        self.circleView.centerOnXAndY()
        self.circleView.makeRound()

        self.definitionLabel.setSize(withWidth: self.circleView.width * 0.8)
        self.definitionLabel.centerOnXAndY()

        self.emotionLabel.setSize(withWidth: self.circleView.width)

        self.definitionLabel.top += self.emotionLabel.height

        self.emotionLabel.centerOnX()
        self.emotionLabel.match(.bottom, to: .top, of: self.definitionLabel, offset: .negative(.standard))
    }
}
