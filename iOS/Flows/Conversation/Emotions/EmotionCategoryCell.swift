//
//  EmotionCell.swift
//  Jibber
//
//  Created by Benji Dodgson on 3/27/22.
//  Copyright © 2022 Benjamin Dodgson. All rights reserved.
//

import Foundation
import Localization

struct EmotionCategoryModel: Hashable {
    var category: EmotionCategory
    var selectedEmotions: [Emotion]
}

class EmotionSelectionView: BaseView {
    private let label = ThemeLabel(font: .small)
    let borderView = BaseView()
    
    override func initializeSubviews() {
        super.initializeSubviews()
        
        self.addSubview(self.borderView)
        
        self.addSubview(self.label)
        self.label.textAlignment = .center
    }
    
    func configure(with item: Emotion, isSelected: Bool) {
        let color = item.color

        self.label.setText(item.description)
        self.label.textColor = color
        
        self.borderView.layer.borderColor = isSelected ? color.cgColor : color.withAlphaComponent(0.2).cgColor
        self.borderView.layer.borderWidth = 2
        self.borderView.layer.masksToBounds = false
        
        self.borderView.backgroundColor = isSelected ? color.withAlphaComponent(0.2) : .clear
        self.setNeedsLayout()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
                
        self.label.setSize(withWidth: 200)
        
        self.borderView.makeRound()
        
        self.label.centerOnXAndY()
        
        self.borderView.expandToSuperviewSize()
    }
}

class EmotionCategoryCell: CollectionViewManagerCell, ManageableCell {
    typealias ItemType = EmotionCategoryModel
    
    var currentItem: EmotionCategoryModel?
    
    let label = ThemeLabel(font: .regular)

    var didSelectEmotion: ((Emotion) -> Void)?
    
    override func initializeSubviews() {
        super.initializeSubviews()
        
        self.contentView.set(backgroundColor: .B6)
        self.contentView.layer.cornerRadius = Theme.cornerRadius
        self.contentView.clipsToBounds = true
        self.label.alpha = 0.8
    }
    
    func configure(with item: EmotionCategoryModel) {
        self.contentView.removeAllSubviews()
        
        self.contentView.addSubview(self.label)
        let title = localized(item.category.title).firstCapitalized
        self.label.setText(title)
        
        item.category.emotions.forEach { emotion in
            let view = EmotionSelectionView()
            view.configure(with: emotion, isSelected: item.selectedEmotions.contains(emotion))
            view.didSelect { [unowned self] in
                self.didSelectEmotion?(emotion)
            }
            self.contentView.addSubview(view)
        }
        
        self.layoutNow()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        let padding = Theme.ContentOffset.long
        let spacing = Theme.ContentOffset.short
        
        self.label.setSize(withWidth: self.contentView.width - padding.value.doubled)
        self.label.pin(.top, offset: padding)
        self.label.pin(.left, offset: padding)
        
        var currentXOffset: CGFloat = padding.value
        var currentYOffset: CGFloat = self.label.bottom + padding.value.doubled
        
        self.contentView.subviews.forEach { view in
            if view is EmotionSelectionView {
                view.layoutNow()
                
                view.origin = CGPoint(x: currentXOffset, y: currentYOffset)
                
                if view.right + spacing.value > self.contentView.width - padding.value {
                    view.origin = CGPoint(x: padding.value,
                                          y: currentYOffset + view.height + spacing.value)
                }
                
                currentXOffset = view.right + spacing.value
                currentYOffset = view.top
            }
        }
    }
}
