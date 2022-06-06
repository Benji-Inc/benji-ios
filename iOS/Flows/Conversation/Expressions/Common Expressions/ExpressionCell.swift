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
    var coreEmotion: Emotion
}

class ExpressionCell: CollectionViewManagerCell, ManageableCell {
    typealias ItemType = ExpressionModel
    
    var currentItem: ExpressionModel?
    
    private let personView = PersonGradientView()
    
    override func initializeSubviews() {
        super.initializeSubviews()
        
        self.contentView.addSubview(self.personView)
    }
    
    func configure(with item: ExpressionModel) {
        if let expression = item.existingExpression {
            self.personView.set
            self.personView.set(emotionCounts: expression.emotionCounts)
        } else {
            
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        self.personView.expandToSuperviewSize()
    }
}
