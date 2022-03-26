//
//  MessageContextView.swift
//  Jibber
//
//  Created by Benji Dodgson on 3/26/22.
//  Copyright © 2022 Benjamin Dodgson. All rights reserved.
//

import Foundation

class MessageContextSelectionView: BaseView {
    
    let lineView = BaseView()
    let label = ThemeLabel(font: .regular)
    let descriptionLabel = ThemeLabel(font: .small)
    
    let context: MessageContext
    
    enum State {
        case hidden
        case visible
        case highlighted
    }
    
    private var state: State = .hidden
    
    init(with context: MessageContext) {
        self.context = context
        super.init()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func initializeSubviews() {
        super.initializeSubviews()
        
        self.addSubview(self.label)
        self.label.alpha = 0.0
        self.label.setText(self.context.displayName)
        
        self.addSubview(self.descriptionLabel)
        self.descriptionLabel.alpha = 0.0
        self.descriptionLabel.setText(self.context.description)
        
        self.addSubview(self.lineView)
        self.lineView.alpha = 0.0
        
        self.lineView.set(backgroundColor: .T1)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        self.descriptionLabel.setSize(withWidth: self.width)
        self.descriptionLabel.pin(.bottom, offset: .short)
        self.descriptionLabel.pin(.left)
        
        self.label.setSize(withWidth: self.width)
        self.label.match(.bottom, to: .top, of: self.descriptionLabel, offset: .short)
        self.label.pin(.left)
        
        self.width = self.descriptionLabel.width
        self.height = 50
        
        self.lineView.height = 1
        self.lineView.pin(.bottom)
        self.lineView.width = 0
    }
    
    private var animationTask: Task<Void, Never>?
    
    func update(state: State) {
        guard self.state != state else { return }
        
        self.state = state
        
        // Cancel any currently running tasks so we don't trigger the animation multiple times.
        self.animationTask?.cancel()
        
        self.animationTask = Task { [weak self] in
            guard let `self` = self else { return }
            
            switch self.state {
            case .hidden:
                
                await UIView.awaitAnimation(with: .standard, animations: {
                    self.label.alpha = 0.0
                    self.descriptionLabel.alpha = 0.0
                    self.lineView.alpha = 0
                    self.lineView.width = 0
                })
                
                await UIView.awaitSpringAnimation(with: .standard, animations: {
                    self.right = 0
                })

            case .visible:
                
                await UIView.awaitSpringAnimation(with: .standard, animations: {
                    self.left = Theme.ContentOffset.long.value
                })
                
                await UIView.awaitAnimation(with: .standard, animations: {
                    self.label.alpha = 0.5
                    self.descriptionLabel.alpha = 0.5
                    self.lineView.alpha = 0
                    self.lineView.width = 0
                })
            case .highlighted:
                
                await UIView.awaitAnimation(with: .standard, animations: {
                    self.label.alpha = 1.0
                    self.descriptionLabel.alpha = 1.0
                    self.lineView.alpha = 1.0
                    self.lineView.width = self.width
                })
            }
        }
    }
}
