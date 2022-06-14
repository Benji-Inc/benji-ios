//
//  TabView.swift
//  Jibber
//
//  Created by Benji Dodgson on 6/9/22.
//  Copyright © 2022 Benjamin Dodgson. All rights reserved.
//

import Foundation

class TabView: BaseView {
    
    let darkblur = DarkBlurView()
    let membersButton = ThemeButton()
    let conversationsButton = ThemeButton()
    let noticesButton = ThemeButton()
    
    enum State {
        case members
        case conversations
        case notices
    }
    
    @Published var state: State = .members
    
    override func initializeSubviews() {
        super.initializeSubviews()
        
        self.addSubview(self.darkblur)
        self.addSubview(self.membersButton)
        
        let pointSize: CGFloat = 20
        
        self.membersButton.set(style: .image(symbol: .person3,
                                             palletteColors: [.white],
                                             pointSize: pointSize,
                                             backgroundColor: .clear))
        
        self.addSubview(self.conversationsButton)
        self.conversationsButton.set(style: .image(symbol: .rectangleStack,
                                                   palletteColors: [.white],
                                                   pointSize: pointSize,
                                                   backgroundColor: .clear))
        
        self.addSubview(self.noticesButton)
        self.noticesButton.set(style: .image(symbol: .bell,
                                             palletteColors: [.white],
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
        
        let buttonWidth = self.width * 0.33
        
        self.membersButton.height = self.height
        self.membersButton.width = buttonWidth
        self.membersButton.pin(.left)
        self.membersButton.centerOnY()
        
        self.conversationsButton.height = self.height
        self.conversationsButton.width = buttonWidth
        self.conversationsButton.centerOnXAndY()
        
        self.noticesButton.height = self.height
        self.noticesButton.width = buttonWidth
        self.noticesButton.pin(.right)
        self.noticesButton.centerOnY()
    }
    
    private func handle(state: State) {
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
        
        UIView.animate(withDuration: Theme.animationDurationFast) {
            self.membersButton.alpha = self.membersButton.isSelected ? 1.0 : 0.5
            self.conversationsButton.alpha = self.conversationsButton.isSelected ? 1.0 : 0.5
            self.noticesButton.alpha = self.noticesButton.isSelected ? 1.0 : 0.5
        } completion: { _ in
            
        }

    }
}
