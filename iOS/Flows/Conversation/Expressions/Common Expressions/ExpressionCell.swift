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
    var coreEmotion: Emotion?
    var color: UIColor
}

class ExpressionCell: CollectionViewManagerCell, ManageableCell {
    typealias ItemType = ExpressionModel
    
    var currentItem: ExpressionModel?
    
    private let personView = PersonGradientView()
    
    private let addView = BaseView()
    private let label = ThemeLabel(font: .small)
    
    override func initializeSubviews() {
        super.initializeSubviews()
        
        self.contentView.addSubview(self.personView)
        self.contentView.addSubview(self.addView)
        
        self.addView.set(backgroundColor: .B1withAlpha)
        
        self.addView.layer.borderColor = ThemeColor.BORDER.color.cgColor
        self.addView.layer.borderWidth = 1.0
        
        self.addView.addSubview(self.label)
        self.label.textAlignment = .center
    }
    
    func configure(with item: ExpressionModel) {
        
        self.addView.isVisible = item.existingExpression.isNil
        self.personView.alpha = 0.5
        
        if let expression = item.existingExpression {
            self.personView.set(expression: expression)
        } else {
            self.personView.set(emotionCounts: [item.coreEmotion: 1])
        }
        
        self.label.setText(item.coreEmotion.description)
        self.label.textColor = item.coreEmotion.color.withAlphaComponent(0.5)
        
        self.setNeedsLayout()
    }
    
    override func update(isSelected: Bool) {
        guard let item = self.currentItem else { return }
        
        let color = item.coreEmotion.color
        self.label.textColor = isSelected ? color : color.withAlphaComponent(0.5)
        self.personView.alpha = isSelected ? 1.0 : 0.5
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        self.personView.squaredSize = self.width
        self.personView.centerOnXAndY()
        
        self.addView.frame = self.personView.frame
        self.addView.makeRound()
        
        self.label.setSize(withWidth: self.width)
        self.label.centerOnXAndY()
    }
}
