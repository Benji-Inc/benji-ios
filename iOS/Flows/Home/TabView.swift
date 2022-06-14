//
//  TabView.swift
//  Jibber
//
//  Created by Benji Dodgson on 6/9/22.
//  Copyright © 2022 Benjamin Dodgson. All rights reserved.
//

import Foundation

class TabView: BaseView, HomeStateHandler {
    
    let darkblur = VibrancyView()
    let membersButton = ThemeButton()
    let conversationsButton = ThemeButton()
    let noticesButton = ThemeButton()
    
    let barView = BaseView()
    
    enum State {
        case members
        case conversations
        case notices
    }
    
    @Published var state: State = .members
    
    var buttons: [ThemeButton] {
        return [self.membersButton, self.conversationsButton, self.noticesButton]
    }
    
    override func initializeSubviews() {
        super.initializeSubviews()
        
        self.addSubview(self.darkblur)
        self.addSubview(self.barView)
        self.barView.set(backgroundColor: .D6)
        
        self.addSubview(self.membersButton)
        
        let pointSize: CGFloat = 18
        
        self.membersButton.set(style: .image(symbol: .person3,
                                             palletteColors: [.D6],
                                             pointSize: pointSize,
                                             backgroundColor: .clear))
        
        self.addSubview(self.conversationsButton)
        self.conversationsButton.set(style: .image(symbol: .rectangleStack,
                                                   palletteColors: [.D6],
                                                   pointSize: pointSize,
                                                   backgroundColor: .clear))
        
        self.addSubview(self.noticesButton)
        self.noticesButton.set(style: .image(symbol: .bell,
                                             palletteColors: [.D6],
                                             pointSize: pointSize,
                                             backgroundColor: .clear))
        
        self.setupHandlers()
    }
    
    private func setupHandlers() {
        self.membersButton.didSelect { [unowned self] in
            self.state = .members
        }
        
        self.conversationsButton.didSelect { [unowned self] in
            self.state = .conversations
        }
        
        self.noticesButton.didSelect { [unowned self] in
            self.state = .notices
        }
        
        self.$state
            .removeDuplicates()
            .mainSink { [unowned self] state in
                self.handle(state: state)
            }.store(in: &self.cancellables)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        self.darkblur.expandToSuperviewSize()
        self.darkblur.makeRound()
        self.darkblur.layer.maskedCorners = [.layerMinXMinYCorner, .layerMinXMaxYCorner]
        
        let buttonWidth = (self.width - Theme.ContentOffset.standard.value.doubled) * 0.33
        
        self.membersButton.height = self.height
        self.membersButton.width = buttonWidth
        self.membersButton.pin(.left, offset: .standard)
        self.membersButton.centerOnY()
        
        self.conversationsButton.height = self.height
        self.conversationsButton.width = buttonWidth
        self.conversationsButton.centerOnXAndY()
        
        self.noticesButton.height = self.height
        self.noticesButton.width = buttonWidth
        self.noticesButton.pin(.right, offset: .standard)
        self.noticesButton.centerOnY()
        
        self.barView.height = 2
        self.barView.pin(.bottom)
        
        self.buttons.forEach { button in
            if button.isSelected {
                self.barView.centerX = button.centerX
            }
        }
    }
    
    private var stateTask: Task<Void, Never>?

    func handleHome(state: HomeState) {
        self.stateTask?.cancel()
        
        self.stateTask = Task { [weak self] in
            guard let `self` = self else { return }
            
            await UIView.awaitSpringAnimation(with: .slow, delay: 0.3, animations: {
                switch state {
                case .initial, .shortcuts:
                    
                    self.buttons.forEach { button in
                        button.transform = CGAffineTransform.init(scaleX: 0.5, y: 0.5)
                        button.alpha = 0
                    }
                case .tabs:
                    self.buttons.forEach { button in
                        button.transform = .identity
                        button.alpha = button.isSelected ? 1.0 : 0.5
                    }
                }
                
                self.setNeedsLayout()
            })
        }
    }
    
    private func handle(state: State) {
        
        self.updateButtonStates(for: state)
        
        Task {
            async let first: () = UIView.awaitSpringAnimation(with: .standard, delay: 0.0, animations: {
                self.barView.width = 4
                self.layoutNow()
            })
            
            async let second: () = UIView.awaitSpringAnimation(with: .standard, delay: 0.15, animations: {
                self.barView.width = 20
                self.layoutNow()
            })

            async let third: () = UIView.awaitAnimation(with: .fast, delay: 0.35, animations: {
                self.membersButton.alpha = self.membersButton.isSelected ? 1.0 : 0.5
                self.conversationsButton.alpha = self.conversationsButton.isSelected ? 1.0 : 0.5
                self.noticesButton.alpha = self.noticesButton.isSelected ? 1.0 : 0.5
            })
            
            let _: [()] = await [first, second, third]
        }
    }
    
    private func updateButtonStates(for state: State) {
        switch state {
        case .members:
            self.membersButton.isSelected = true
            self.conversationsButton.isSelected = false
            self.noticesButton.isSelected = false
        case .conversations:
            self.membersButton.isSelected = false
            self.conversationsButton.isSelected = true
            self.noticesButton.isSelected = false
        case .notices:
            self.membersButton.isSelected = false
            self.conversationsButton.isSelected = false
            self.noticesButton.isSelected = true
        }
    }
}
