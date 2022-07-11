//
//  QuickExpressionsView.swift
//  Jibber
//
//  Created by Benji Dodgson on 7/10/22.
//  Copyright © 2022 Benjamin Dodgson. All rights reserved.
//

import Foundation

class UniqueExpressionView: BaseView {
    
    let uniqueExpression: UniqueExpression
    let personView = PersonGradientView()
    
    init(with expression: UniqueExpression) {
        self.uniqueExpression = expression
        super.init()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func initializeSubviews() {
        super.initializeSubviews()
        
        Task {
            if let expression = try await self.uniqueExpression.getExpression() {
                self.personView.set(expression: expression, author: User.current())
            } else {
                self.personView.set(emotionCounts: [self.uniqueExpression.emotion: 1])
            }
        }
    }
}

class QuickExpressionsView: BaseView {
    
    var didSelectExpression: ((UniqueExpression) -> Void)?
    
    override func initializeSubviews() {
        super.initializeSubviews()
        
        self.alpha = 0
        
        UniqueExpression.allCases.forEach { unique in
            let view = UniqueExpressionView(with: unique)
            view.personView.expressionVideoView.shouldPlay = true
            view.didSelect { [unowned self] in
                self.didSelectExpression?(unique)
            }
            self.addSubview(view)
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        let padding: CGFloat = Theme.ContentOffset.standard.value
        
        var xOffset: CGFloat = padding
        
        var count: Int = 0
        self.subviews.forEach { view in
            if let personView = view as? UniqueExpressionView {
                personView.frame = CGRect(x: xOffset,
                                          y: padding.half,
                                          width: self.height - padding,
                                          height: self.height - padding)
                xOffset += view.width + padding
                count += 1
            }
        }
        
        self.width = xOffset
        
        self.makeRound()
        self.clipsToBounds = false
        self.showShadow(withOffset: 0, opacity: 0.5, radius: 5, color: ThemeColor.B0.color)
    }
    
    func reveal(in superview: UIView) async {
        superview.addSubview(self)
        
        self.layoutNow()
        
        await UIView.awaitSpringAnimation(with: .slow) {
            self.alpha = 1.0
        }
    }
    
    func dismiss() async {
        await UIView.awaitSpringAnimation(with: .slow) {
            self.alpha = 0.0
        }
        
        await Task.sleep(seconds: 0.1)
        
        self.removeFromSuperview()
    }
}
