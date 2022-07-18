//
//  QuickExpressionsView.swift
//  Jibber
//
//  Created by Benji Dodgson on 7/10/22.
//  Copyright © 2022 Benjamin Dodgson. All rights reserved.
//

import Foundation

class FavoriteExpressionView: BaseView {
    
    let favoriteType: FavoriteType
    let personView = PersonGradientView()
    
    init(with expression: FavoriteType) {
        self.favoriteType = expression
        super.init()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func initializeSubviews() {
        super.initializeSubviews()
        
        self.addSubview(self.personView)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        self.personView.expandToSuperviewSize()
    }
    
    func loadExpression() async {
        if let expression = try? await self.favoriteType.getExpression() {
            self.personView.set(expression: expression, author: User.current())
        } else {
            // show label?
        }

        self.personView.set(emotionCounts: [self.favoriteType.emotion: 1])
    }
}

class FavoriteExpressionsView: BaseView {
    
    var didSelectExpression: ((FavoriteType) -> Void)?
    static let height: CGFloat = 50
    private let darkBlur = DarkBlurView()
    private let pool = TaskPool()
    
    private lazy var expression1 = FavoriteExpressionView(with: .love)
    private lazy var expression2 = FavoriteExpressionView(with: .sad)
    private lazy var expression3 = FavoriteExpressionView(with: .agree)
    private lazy var expression4 = FavoriteExpressionView(with: .happy)
    private lazy var expression5 = FavoriteExpressionView(with: .laughter)
    
    private lazy var allViews = [self.expression1, expression2, expression3, expression4, expression5]
    
    override func initializeSubviews() {
        super.initializeSubviews()
        
        self.addSubview(self.darkBlur)
                
        self.alpha = 0
        self.darkBlur.roundCorners()
        
        self.allViews.forEach { view in
            view.alpha = 0
            view.transform = CGAffineTransform.init(scaleX: 0.001, y: 0.001)
            view.didSelect { [unowned self] in
                self.didSelectExpression?(view.favoriteType)
            }
            self.addSubview(view)
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        self.height = FavoriteExpressionsView.height
        
        let padding: CGFloat = Theme.ContentOffset.standard.value
        
        var xOffset: CGFloat = padding
        
        var count: Int = 0
        self.allViews.forEach { view in
            view.frame = CGRect(x: xOffset,
                                y: padding.half,
                                width: self.height - padding,
                                height: self.height - padding)
            xOffset += view.width + padding
            count += 1
        }
        
        self.width = xOffset
        
        self.darkBlur.expandToSuperviewSize()
        
        self.clipsToBounds = false
        self.showShadow(withOffset: 0, opacity: 0.5, radius: 5, color: ThemeColor.B0.color)
    }
    
    func reveal(in superview: UIView) async {
        guard self.superview.isNil else { return }
        
        superview.addSubview(self)
        
        self.layoutNow()

        UIView.animate(withDuration: Theme.animationDurationFast) {
            self.alpha = 1.0
        }
                
        var delay: TimeInterval = 0.05
        for (index, view) in self.allViews.enumerated() {
            delay += Double(index) * 0.025
            
            UIView.animate(withDuration: Theme.animationDurationFast, delay: delay, options: .curveEaseInOut) {
                view.alpha = 1.0
                view.transform = .identity
            }
        }
                
        await self.allViews.asyncForEach { view in
            Task {
                await view.loadExpression()
            }.add(to: self.pool)
            view.personView.expressionVideoView.shouldPlay = true
        }
    }
    
    func dismiss() async {
        await UIView.awaitSpringAnimation(with: .slow) {
            self.alpha = 0.0
            self.allViews.forEach { view in
                view.alpha = 0
            }
        }
        
        self.allViews.forEach { view in
            view.transform = CGAffineTransform.init(scaleX: 0.001, y: 0.001)
            view.personView.expressionVideoView.shouldPlay = false
        }
        
        self.pool.cancelAndRemoveAll()
        
        await Task.sleep(seconds: 0.1)
        
        self.removeFromSuperview()
    }
}
