//
//  ExpressionSummaryView.swift
//  Jibber
//
//  Created by Benji Dodgson on 6/24/22.
//  Copyright © 2022 Benjamin Dodgson. All rights reserved.
//

import Foundation

class ExpressionSummaryView: BaseView, MessageConfigureable {
    
    let expressionsView = MessageExpressionsView()
    
    override func initializeSubviews() {
        super.initializeSubviews()
        
        self.addSubview(self.expressionsView)
    }
    
    func configure(for message: Messageable) {
        // Grab all the expressions for a message
        self.expressionsView.configure(with: message.expressions)
        self.layoutNow()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        self.expressionsView.expandToSuperviewSize()
    }
}

class MessageExpressionsView: BaseView {
        
    private let scrollView = UIScrollView()
    
    private var models: [ExpressionInfo] = []
    var didSelectExpression: ((ExpressionInfo) -> Void)? = nil 
    
    override func initializeSubviews() {
        super.initializeSubviews()
        
        self.addSubview(self.scrollView)
        self.scrollView.showsHorizontalScrollIndicator = false
        self.clipsToBounds = false
        self.scrollView.clipsToBounds = false
    }
    
    func configure(with models: [ExpressionInfo]) {
        guard models != self.models else { return }
        
        self.models = models
                
        self.scrollView.removeAllSubviews()
        
        for model in self.models {
            let view = ExpressionContentView()
            view.configure(with: model)
            view.didSelect { [unowned self] in
                self.didSelectExpression?(model)
            }
            self.scrollView.addSubview(view)
        }
        
        self.layoutNow()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        self.expandToSuperviewSize()
        
        self.scrollView.expandToSuperviewSize()
        
        var xOffset: CGFloat = 0
        var count: Int = 0
        self.scrollView.subviews.forEach { view in
            if let personView = view as? ExpressionContentView {
                personView.frame = CGRect(x: xOffset,
                                          y: 0,
                                          width: 30,
                                          height: self.height)
                xOffset += view.width + Theme.ContentOffset.xtraLong.value
                count += 1
            }
        }
        
        xOffset -= Theme.ContentOffset.xtraLong.value
        
        self.scrollView.contentSize = CGSize(width: xOffset, height: self.height)
    }
}

class ExpressionContentView: BaseView {
    
    let personView = PersonGradientView()
    let label = ThemeLabel(font: .xtraSmall)
    
    private(set) var personId: String?
    
    override func initializeSubviews() {
        super.initializeSubviews()
        
        self.addSubview(self.personView)
        self.addSubview(self.label)
                
        self.label.textAlignment = .center
        self.label.alpha = 0.25
        
        self.clipsToBounds = false
    }
    
    /// A reference to a task for configuring the cell.
    private var configurationTask: Task<Void, Never>?

    func configure(with item: ExpressionInfo) {
        self.configurationTask?.cancel()
        
        self.personView.isVisible = true

        self.configurationTask = Task { [weak self] in
            guard let `self` = self else { return }
            
            guard let expression = try? await Expression.getObject(with: item.expressionId) else { return }

            self.personView.set(expression: expression, author: nil)
            let dateString = expression.createdAt?.getTimeAgoString()
            self.label.setText(dateString)
            
            self.setNeedsLayout()
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        self.personView.squaredSize = self.width
        self.personView.centerOnX()
        self.personView.pin(.top)
        
        self.label.setSize(withWidth: self.width * 1.5)
        self.label.centerOnX()
        self.label.match(.top, to: .bottom, of: self.personView, offset: .short)
    }
}
