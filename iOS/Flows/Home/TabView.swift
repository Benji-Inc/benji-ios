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
    let shortcutButton = ThemeButton()
    
    enum State {
        case members
        case conversations
    }
    
    @Published var state: State = .members
    
    override func initializeSubviews() {
        super.initializeSubviews()
        
        self.addSubview(self.darkblur)
        self.addSubview(self.membersButton)
        
        var config = UIImage.SymbolConfiguration(pointSize: 25)
        var highlightConfig = UIImage.SymbolConfiguration(pointSize: 23)
                                        
        config = config.applying(UIImage.SymbolConfiguration.init(paletteColors: [ThemeColor.white.color]))
        highlightConfig = highlightConfig.applying(UIImage.SymbolConfiguration.init(paletteColors: [ThemeColor.white.color]))
        
        self.membersButton.set(style: .image(symbol: .person3,
                                             config: config,
                                             hightlightConfig: highlightConfig,
                                             backgroundColor: .clear))
        
        self.addSubview(self.shortcutButton)
        var shortcutConfig = UIImage.SymbolConfiguration(pointSize: 30)
        var shortcutHightlightConfig = UIImage.SymbolConfiguration(pointSize: 28)
        shortcutConfig = shortcutConfig.applying(UIImage.SymbolConfiguration.init(paletteColors: [ThemeColor.white.color]))
        shortcutHightlightConfig = shortcutHightlightConfig.applying(UIImage.SymbolConfiguration.init(paletteColors: [ThemeColor.white.color]))
        
        self.shortcutButton.set(style: .image(symbol: .bolt,
                                              config: shortcutConfig,
                                              hightlightConfig: shortcutHightlightConfig,
                                              backgroundColor: .D6))
        
        self.addSubview(self.conversationsButton)
        self.conversationsButton.set(style: .image(symbol: .rectangleStack,
                                                   config: config,
                                                   hightlightConfig: highlightConfig,
                                                   backgroundColor: .clear))
        
        self.setupHandlers()
    }
    
    private func setupHandlers() {
        self.membersButton.didSelect { [unowned self] in
            self.state = .members
        }
        
        self.shortcutButton.didSelect { [unowned self] in
            //self.state = .shortcut
        }

        self.conversationsButton.didSelect { [unowned self] in
            self.state = .conversations
        }
        
        self.$state
            .removeDuplicates()
            .mainSink { [unowned self] state in
            self.handle(state: state)
        }.store(in: &self.cancellables)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        self.makeRound()
        
        self.darkblur.expandToSuperviewSize()
        
        self.shortcutButton.squaredSize = self.height - Theme.ContentOffset.long.value.doubled
        self.shortcutButton.centerOnXAndY()
        self.shortcutButton.makeRound()
        
        let buttonWidth = (self.width - self.shortcutButton.width) * 0.4
        
        self.membersButton.height = self.height
        self.membersButton.width = buttonWidth
        self.membersButton.pin(.left)
        self.membersButton.centerOnY()
        
        self.conversationsButton.height = self.height
        self.conversationsButton.width = buttonWidth
        self.conversationsButton.pin(.right)
        self.conversationsButton.centerOnY()
    }
    
    private func handle(state: State) {
        switch state {
        case .members:
            self.membersButton.isSelected = true
            self.conversationsButton.isSelected = false
        case .conversations:
            self.membersButton.isSelected = false
            self.conversationsButton.isSelected = true
        }
    }
}
