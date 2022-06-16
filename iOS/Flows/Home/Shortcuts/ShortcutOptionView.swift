//
//  ShortcutOptionView.swift
//  Jibber
//
//  Created by Benji Dodgson on 6/15/22.
//  Copyright © 2022 Benjamin Dodgson. All rights reserved.
//

import Foundation

class ShortcutOptionView: BaseView {
    
    static let height: CGFloat = 60
    
    enum OptionType {
        case newMessage
        case newConversation
        case newVibe
        
        var symbol: ImageSymbol {
            switch self {
            case .newMessage:
                return .plus
            case .newConversation:
                return .bolt
            case .newVibe:
                return .bell
            }
        }
        
        var text: String {
            switch self {
            case .newMessage:
                return "New Message"
            case .newConversation:
                return "New Conversation"
            case .newVibe:
                return "New Vibe"
            }
        }
    }
    
    enum State {
        case initial
        case collapsed
        case expanded
    }
    
    let imageView = SymbolImageView()
    let titleLabel = ThemeLabel(font: .regular)
    
    @Published var state: State = .expanded
    
    let type: OptionType
    var didSelectOption: CompletionOptional = nil
    
    init(with type: OptionType) {
        self.type = type
        super.init()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func initializeSubviews() {
        super.initializeSubviews()
        
        self.addSubview(self.imageView)
        self.imageView.set(symbol: self.type.symbol)
        
        self.addSubview(self.titleLabel)
        self.titleLabel.setText(self.type.text)
        
        self.$state.removeDuplicates()
            .mainSink { [unowned self] state in
                self.handle(state: state)
            }.store(in: &self.cancellables)
        
        //self.alpha = 0
       // self.titleLabel.alpha = 0
        //self.imageView.alpha = 0
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        self.height = ShortcutOptionView.height
        
        self.imageView.squaredSize = self.height - Theme.ContentOffset.standard.value.doubled
        self.imageView.pin(.left, offset: .standard)
        self.imageView.centerOnY()
        
        self.titleLabel.setSize(withWidth: 200)
        self.titleLabel.match(.left, to: .right, of: self.imageView, offset: .standard)
        self.titleLabel.centerOnY()
        
        switch self.state {
        case .initial, .collapsed:
            self.width = self.height
        case .expanded:
            self.width = self.imageView.right + self.titleLabel.width + Theme.ContentOffset.standard.value.doubled
        }
    }
    
    private var stateTask: Task<Void, Never>?

    func handle(state: State) {
    
        self.stateTask?.cancel()
        
        self.stateTask = Task { [weak self] in
            guard let `self` = self else { return }
            
//            switch state {
//            case .initial:
//                await self.animateInitial()
//            case .collapsed:
//                await self.animateCollapsed()
//            case .expanded:
//                await self.animateExpand()
//            }
        }
    }
    
    private func animateInitial() async {
        await UIView.awaitAnimation(with: .slow, animations: {
//            self.alpha = 0
//            self.titleLabel.alpha = 0
//            self.imageView.alpha = 0
        })
        
    }
    
    private func animateCollapsed() async {
        await UIView.awaitAnimation(with: .slow, animations: {
            self.alpha = 1
            self.titleLabel.alpha = 0
        })
    }
    
    private func animateExpand() async {
        await UIView.awaitAnimation(with: .slow, animations: {
            self.alpha = 0
            self.titleLabel.alpha = 1.0 
        })
    }
}
