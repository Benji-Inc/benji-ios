//
//  ExpressionCell.swift
//  Jibber
//
//  Created by Benji Dodgson on 6/6/22.
//  Copyright © 2022 Benjamin Dodgson. All rights reserved.
//

import Foundation

struct ExpressionModel: Hashable {
    var existingExpression: Expression?
    var defaultEmotion: Emotion
}

class ExpressionCell: CollectionViewManagerCell, ManageableCell {
    typealias ItemType = ExpressionModel
    
    var currentItem: ExpressionModel?
    
    private let personView = PersonGradientView()
    
    private let emotionSelectionView = EmotionSelectionView()
    
    override func initializeSubviews() {
        super.initializeSubviews()
        
        self.contentView.addSubview(self.personView)
        self.contentView.addSubview(self.emotionSelectionView)
        self.emotionSelectionView.clipsToBounds = false
    }
    
    func configure(with item: ExpressionModel) {
        
        self.emotionSelectionView.isVisible = item.existingExpression.isNil
        self.personView.isVisible = self.emotionSelectionView.isHidden
        
        if let expression = item.existingExpression {
            self.personView.set(expression: expression)
        } else {
            self.emotionSelectionView.configure(with: item.defaultEmotion, isSelected: false)
        }
        
        self.setNeedsLayout()
    }
    
    override func update(isSelected: Bool) {
        guard let item = self.currentItem else { return }
        
        if let expression = item.existingExpression {
            self.personView.set(expression: expression)
            self.personView.alpha = isSelected ? 1.0 : 0.2
        } else {
            self.emotionSelectionView.configure(with: item.defaultEmotion, isSelected: isSelected)
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        self.personView.squaredSize = self.width
        self.personView.centerOnXAndY()
        
        self.emotionSelectionView.squaredSize = self.width - 4
        self.emotionSelectionView.centerOnXAndY()
    }
}
