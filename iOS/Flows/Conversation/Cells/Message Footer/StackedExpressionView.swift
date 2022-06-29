//
//  ReactionsFooterView.swift
//  Jibber
//
//  Created by Benji Dodgson on 6/29/22.
//  Copyright © 2022 Benjamin Dodgson. All rights reserved.
//

import Foundation

class StackedExpressionView: BaseView {
    
    var itemHeight: CGFloat = MessageFooterView.collapsedHeight
    
    private let label = ThemeLabel(font: .small)
    private var expressions: [ExpressionInfo] = []
    var max: Int = 3
    
    let addExpressionView = AddExpressionView()
    
    var didTapAdd: CompletionOptional = nil
    var didSelectExpression: ((ExpressionInfo) -> Void)?
    
    override func initializeSubviews() {
        super.initializeSubviews()
        
        self.addExpressionView.didSelect { [unowned self] in
            self.didTapAdd?() 
        }
        
        self.clipsToBounds = false
    }
    
    func configure(with message: Messageable) {
        
        self.removeAllSubviews()
        
        if message.authorExpression.isNil {
            self.addExpressionView.configure(with: nil)
            self.addSubview(self.addExpressionView)
        }
        
        let nonAuthorExpressions = message.expressions.filter { expression in
            return expression.authorId != User.current()?.objectId
        }
        
        self.configure(with: nonAuthorExpressions)
    }
    
    private func configure(with expressions: [ExpressionInfo]) {
        guard self.expressions != expressions else { return }
        
        self.expressions = expressions
        
        for (index, info) in expressions.enumerated() {
            if index <= self.max - 1 {
                let view = PersonGradientView()
                view.didSelect { [unowned self] in
                    self.didSelectExpression?(info)
                }
                view.set(info: info, authorId: nil)
                self.addSubview(view)
            }
        }
        
        if expressions.count > self.max {
            let remainder = expressions.count - self.max
            self.label.setText("+\(remainder)")
            self.addSubview(self.label)
        }
        
        self.layoutNow()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        self.height = self.itemHeight
        
        var xOffset: CGFloat = 0
        
        if self.addExpressionView.superview.exists {
            self.addExpressionView.squaredSize = self.height
            self.addExpressionView.pin(.left)
            self.addExpressionView.pin(.top)
            xOffset = self.addExpressionView.right
        }
        
        var count: Int = 0
        self.subviews.forEach { view in
            if let personView = view as? BorderedPersonView {
                personView.shadowLayer.opacity = 0.0
                personView.frame = CGRect(x: xOffset,
                                          y: 0,
                                          width: self.height,
                                          height: self.height)
                xOffset += view.width + Theme.ContentOffset.short.value
                count += 1
            }
        }
        
        xOffset -= Theme.ContentOffset.short.value
         
        if count == self.max {
            self.label.setSize(withWidth: 30)
            xOffset += self.label.width + Theme.ContentOffset.short.value
            self.label.centerOnY()
            self.label.right = xOffset
        }
        
        self.width = xOffset
    }
}
