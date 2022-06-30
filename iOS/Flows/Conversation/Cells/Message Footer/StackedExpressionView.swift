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
        
        self.set(backgroundColor: .B1)
        
        self.addExpressionView.didSelect { [unowned self] in
            self.didTapAdd?() 
        }
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
        
        let padding: CGFloat = Theme.ContentOffset.standard.value
        
        var xOffset: CGFloat = padding
        
        if self.addExpressionView.superview.exists {
            self.addExpressionView.squaredSize = self.height - padding
            self.addExpressionView.pin(.left, offset: .custom(padding))
            self.addExpressionView.pin(.top, offset: .custom(padding.half))
            xOffset += self.addExpressionView.right
        }
        
        var count: Int = 0
        self.subviews.forEach { view in
            if let personView = view as? BorderedPersonView {
                personView.shadowLayer.opacity = 0.0
                personView.frame = CGRect(x: xOffset,
                                          y: padding.half,
                                          width: self.height - padding,
                                          height: self.height - padding)
                xOffset += view.width + padding
                count += 1
            }
        }
                 
        if count == self.max {
            self.label.setSize(withWidth: 30)
            xOffset += self.label.width + padding
            self.label.centerOnY()
            self.label.right = xOffset
        } else if count == 0 {
            xOffset += padding
        }
        
        self.width = xOffset
        
        self.makeRound()
        self.clipsToBounds = false
        self.showShadow(withOffset: 0, opacity: 0.5, radius: 5, color: ThemeColor.B0.color)
    }
}
