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
    let connectionsButton = SymbolButton(symbol: .person3)
    let conversationsButton = SymbolButton(symbol: .rectangleStack)
    let shortcutButton = ThemeButton()
    
    enum State {
        case connections
        case shortcut
        case conversations
    }
    
    @Published var state: State = .connections
    
    override func initializeSubviews() {
        super.initializeSubviews()
        
        self.addSubview(self.darkblur)
        self.addSubview(self.connectionsButton)
        self.connectionsButton.set(symbol: .person3, pointSize: 38)
        
        self.addSubview(self.shortcutButton)
        let config = UIImage.SymbolConfiguration(pointSize: 40)
        
        self.shortcutButton.set(style: .image(symbol: .bolt, config: config, backgroundColor: .D6))
        //self.shortcutButton.set(symbol: .bolt, pointSize: 40)
        //self.shortcutButton.setb
        
        self.addSubview(self.conversationsButton)
        self.conversationsButton.set(symbol: .rectangleStack, pointSize: 30)
        
        self.connectionsButton.didSelect { [unowned self] in
            self.state = .connections
        }
        
//        self.shortcutButton.didSelect { [unowned self] in
//            self.state = .shortcut
//        }
//
        self.conversationsButton.didSelect { [unowned self] in
            self.state = .conversations
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        self.roundCorners()
        
        self.darkblur.expandToSuperviewSize()
        
        self.shortcutButton.squaredSize = self.height - Theme.ContentOffset.standard.value.doubled
        self.shortcutButton.centerOnXAndY()
        self.shortcutButton.makeRound()
        
        self.connectionsButton.squaredSize = self.height
        self.connectionsButton.centerX = self.halfWidth.half
        self.connectionsButton.centerOnY()
        
        
        
        self.conversationsButton.squaredSize = self.height
        self.conversationsButton.centerX = self.width - self.halfWidth.half
        self.conversationsButton.centerOnY()
    }
    
    private func handle(state: State) {
        switch state {
        case .connections:
            break
        case .shortcut:
            break
        case .conversations:
            break
        }
    }
}
